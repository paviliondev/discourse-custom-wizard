import ComposerEditor from "discourse/components/composer-editor";
import { default as computed, on } from "discourse-common/utils/decorators";
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import { throttle } from "@ember/runloop";
import { scheduleOnce } from "@ember/runloop";
import { safariHacksDisabled } from "discourse/lib/utilities";
import highlightSyntax from "discourse/lib/highlight-syntax";
import { getToken } from "wizard/lib/ajax";
import { validateUploadedFiles } from "discourse/lib/uploads";

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
        afterComplete() {
          scheduleOnce("afterRender", () => $input.blur().focus());
        },
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

  showUploadModal() {
    $(".wizard-composer-upload").trigger("click");
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
  },
  actions: {
    extraButtons(toolbar) {
      if (this.allowUpload && this.uploadIcon && !this.site.mobileView) {
        toolbar.addButton({
          id: "upload",
          group: "insertions",
          icon: this.uploadIcon,
          title: "upload",
          sendAction: this.showUploadModal,
        });
      }

      const component = this;
      toolbar.addButton({
        id: "link",
        group: "insertions",
        shortcut: "K",
        trimLeading: true,
        sendAction: (event) => component.set("showHyperlinkBox", true),
      });
    },
    previewUpdated($preview) {
      highlightSyntax($preview[0], this.siteSettings, this.session);
      this._super(...arguments);
    },
    addLink(linkName, linkUrl) {
      let link = `[${linkName}](${linkUrl})`;
      this.appEvents.trigger("composer:insert-text", link);
      this.set("showHyperlinkBox", false);
    },
    hideBox() {
      this.set("showHyperlinkBox", false);
    },
  },
});
