import ComposerEditor from "discourse/components/composer-editor";
import { default as computed, on } from "discourse-common/utils/decorators";
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import { throttle } from "@ember/runloop";
import { scheduleOnce, next } from "@ember/runloop";
import {
  safariHacksDisabled,
  caretPosition,
  inCodeBlock,
} from "discourse/lib/utilities";
import highlightSyntax from "discourse/lib/highlight-syntax";
import { getToken } from "wizard/lib/ajax";
import {
  validateUploadedFiles,
  getUploadMarkdown
} from "discourse/lib/uploads";
import {
  cacheShortUploadUrl,
} from "pretty-text/upload-short-url";

const uploadMarkdownResolvers = [];

const uploadHandlers = [];
export default ComposerEditor.extend({
  classNameBindings: ["fieldClass"],
  allowUpload: true,
  showLink: false,
  showHyperlinkBox: false,
  topic: null,
  showToolbar: true,
  focusTarget: "reply",
  canWhisper: false,
  lastValidatedAt: "lastValidatedAt",
  uploadIcon: "upload",
  popupMenuOptions: [],
  draftStatus: "null",

  @on("didInsertElement")
  _composerEditorInit() {
    const $input = $(this.element.querySelector(".d-editor-input"));
    const $preview = $(this.element.querySelector(".d-editor-preview-wrapper"));

    if (this.siteSettings.enable_mentions) {
      $input.autocomplete({
        template: findRawTemplate("user-selector-autocomplete"),
        dataSource: (term) => this.userSearchTerm.call(this, term),
        key: "@",
        transformComplete: (v) => v.username || v.name,
        afterComplete: (value) => {
          this.composer.set("reply", value);
          scheduleOnce("afterRender", () => $input.blur().focus());
        },
        triggerRule: (textarea) =>
          !inCodeBlock(textarea.value, caretPosition(textarea))
      });
    }

    if (this._enableAdvancedEditorPreviewSync()) {
      this._initInputPreviewSync($input, $preview);
    } else {
      $input.on("scroll", () =>
        throttle(this, this._syncEditorAndPreviewScroll, $input, $preview, 20)
      );
    }

    this._bindUploadTarget();
  },
  
  _setUploadPlaceholderSend() {
    if (!this.composer.get("reply")) {
      this.composer.set("reply", "");
    }
    this._super(...arguments);
  },

  _bindUploadTarget() {
    this._super(...arguments);
    const $element = $(this.element);
    
    $element.off("fileuploadsubmit");
    
    $element.on("fileuploadsubmit", (e, data) => {
      const max = this.siteSettings.simultaneous_uploads;

      // Limit the number of simultaneous uploads
      if (max > 0 && data.files.length > max) {
        bootbox.alert(
          I18n.t("post.errors.too_many_dragged_and_dropped_files", { max })
        );
        return false;
      }

      // Look for a matching file upload handler contributed from a plugin
      const matcher = (handler) => {
        const ext = handler.extensions.join("|");
        const regex = new RegExp(`\\.(${ext})$`, "i");
        return regex.test(data.files[0].name);
      };

      const matchingHandler = uploadHandlers.find(matcher);
      if (data.files.length === 1 && matchingHandler) {
        if (!matchingHandler.method(data.files[0], this)) {
          return false;
        }
      }

      // If no plugin, continue as normal
      const isPrivateMessage = this.get("composer.privateMessage");

      data.formData = { type: "composer" };
      data.formData.authenticity_token = getToken();
      if (isPrivateMessage) {
        data.formData.for_private_message = true;
      }
      if (this._pasted) {
        data.formData.pasted = true;
      }

      const opts = {
        user: this.currentUser,
        siteSettings: this.siteSettings,
        isPrivateMessage,
        allowStaffToUploadAnyFileInPm: this.siteSettings
          .allow_staff_to_upload_any_file_in_pm,
      };

      const isUploading = validateUploadedFiles(data.files, opts);

      this.setProperties({ uploadProgress: 0, isUploading });

      return isUploading;
    });
    
    $element.on("fileuploadprogressall", (e, data) => {
      this.set(
        "uploadProgress",
        parseInt((data.loaded / data.total) * 100, 10)
      );
    });
    
    $element.on("fileuploadfail", (e, data) => {
      this._setUploadPlaceholderDone(data);
      this._resetUpload(true);

      const userCancelled = this._xhr && this._xhr._userCancelled;
      this._xhr = null;
      
      if (!userCancelled) {
        displayErrorForUpload(data, this.siteSettings);
      }
    });
    
    $element.on("fileuploadsend", (e, data) => {
      this._pasted = false;
      this._validUploads++;

      this._setUploadPlaceholderSend(data);

      this.appEvents.trigger("wizard-editor:insert-text", {
        fieldId: this.fieldId,
        text: this.uploadPlaceholder
      });
      
      if (data.xhr && data.originalFiles.length === 1) {
        this.set("isCancellable", true);
        this._xhr = data.xhr();
      }
    });
    
    $element.on("fileuploaddone", (e, data) => {
      let upload = data.result;
      
      this._setUploadPlaceholderDone(data);
            
      if (!this._xhr || !this._xhr._userCancelled) {
        const markdown = uploadMarkdownResolvers.reduce(
          (md, resolver) => resolver(upload) || md,
          getUploadMarkdown(upload)
        );

        cacheShortUploadUrl(upload.short_url, upload);
        this.appEvents.trigger(
          "wizard-editor:replace-text", {
            fieldId: this.fieldId,
            oldVal: this.uploadPlaceholder.trim(),
            newVal: markdown 
          }
        );
        this._resetUpload(false);
      } else {
        this._resetUpload(true);
      }
    });
  },
  
  _resetUpload(removePlaceholder) {
    next(() => {
      if (this._validUploads > 0) {
        this._validUploads--;
      }
      if (this._validUploads === 0) {
        this.setProperties({
          uploadProgress: 0,
          isUploading: false,
          isCancellable: false,
        });
      }
      if (removePlaceholder) {
        this.appEvents.trigger(
          "wizard-editor:replace-text", {
            fieldId: this.fieldId,
            oldVal: this.uploadPlaceholder,
            newVal: ""
          }
        );
      }
      this._resetUploadFilenamePlaceholder();
    });
  },
  
  _registerImageScaleButtonClick($preview) {
    const imageScaleRegex = /!\[(.*?)\|(\d{1,4}x\d{1,4})(,\s*\d{1,3}%)?(.*?)\]\((upload:\/\/.*?)\)(?!(.*`))/g;
    $preview.off("click", ".scale-btn").on("click", ".scale-btn", (e) => {
      const index = parseInt($(e.target).parent().attr("data-image-index"), 10);

      const scale = e.target.attributes["data-scale"].value;
      const matchingPlaceholder = this.get("composer.reply").match(
        imageScaleRegex
      );
      
      if (matchingPlaceholder) {
        const match = matchingPlaceholder[index];

        if (match) {
          const replacement = match.replace(
            imageScaleRegex,
            `![$1|$2, ${scale}%$4]($5)`
          );
          
          this.appEvents.trigger(
            "wizard-editor:replace-text", 
            {
              fieldId: this.fieldId,
              oldVal: matchingPlaceholder[index],
              newVal: replacement,
              options: {
                regex: imageScaleRegex,
                index
              }
            }
          );
        }
      }

      e.preventDefault();
      return;
    });
  },
  
  click(e) {
    if ($(e.target).hasClass('wizard-composer-hyperlink')) {
      this.set('showHyperlinkBox', false);
    }
  },
  
  actions: {
    extraButtons(toolbar) {
      const component = this;
      
      if (this.allowUpload && this.uploadIcon && !this.site.mobileView) {
        toolbar.addButton({
          id: "upload",
          group: "insertions",
          icon: this.uploadIcon,
          title: "upload",
          sendAction: (event) => component.send("showUploadModal", event),
        });
      }

      toolbar.addButton({
        id: "link",
        group: "insertions",
        shortcut: "K",
        trimLeading: true,
        unshift: true,
        sendAction: (event) => component.set("showHyperlinkBox", true),
      });
    },
    
    previewUpdated($preview) {
      highlightSyntax($preview[0], this.siteSettings, this.session);
      this._super(...arguments);
    },
    
    addLink(linkName, linkUrl) {
      let link = `[${linkName}](${linkUrl})`;
      this.appEvents.trigger("wizard-editor:insert-text", {
        fieldId: this.fieldId,
        text: link
      });
      this.set("showHyperlinkBox", false);
    },
    
    hideBox() {
      this.set("showHyperlinkBox", false);
    },
    
    showUploadModal() {
      $(this.element.querySelector(".wizard-composer-upload")).trigger("click");
    }
  },
});
