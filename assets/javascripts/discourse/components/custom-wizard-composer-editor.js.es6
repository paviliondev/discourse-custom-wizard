import ComposerEditor from "discourse/components/composer-editor";
import {
  bind,
  default as discourseComputed,
  on,
} from "discourse-common/utils/decorators";
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import { scheduleOnce } from "@ember/runloop";
import { caretPosition, inCodeBlock } from "discourse/lib/utilities";
import highlightSyntax from "discourse/lib/highlight-syntax";
import { alias } from "@ember/object/computed";
import Site from "discourse/models/site";
import { uploadIcon } from "discourse/lib/uploads";
import { dasherize } from "@ember/string";

const IMAGE_MARKDOWN_REGEX = /!\[(.*?)\|(\d{1,4}x\d{1,4})(,\s*\d{1,3}%)?(.*?)\]\((upload:\/\/.*?)\)(?!(.*`))/g;

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
  popupMenuOptions: [],
  draftStatus: "null",
  replyPlaceholder: alias("field.translatedPlaceholder"),
  wizardEventFieldId: null,

  @on("didInsertElement")
  _composerEditorInit() {
    const $input = $(this.element.querySelector(".d-editor-input"));

    if (this.siteSettings.enable_mentions) {
      $input.autocomplete({
        template: findRawTemplate("user-selector-autocomplete"),
        dataSource: (term) => this._userSearchTerm.call(this, term),
        key: "@",
        transformComplete: (v) => v.username || v.name,
        afterComplete: (value) => {
          this.composer.set("reply", value);
          scheduleOnce("afterRender", () => $input.blur().focus());
        },
        triggerRule: (textarea) =>
          !inCodeBlock(textarea.value, caretPosition(textarea)),
      });
    }

    const siteSettings = this.siteSettings;
    if (siteSettings.mentionables_enabled) {
      Site.currentProp("mentionable_items", this.wizard.mentionable_items);
      const { SEPARATOR } = requirejs(
        "discourse/plugins/discourse-mentionables/discourse/lib/discourse-markdown/mentionable-items"
      );
      const { searchMentionableItem } = requirejs(
        "discourse/plugins/discourse-mentionables/discourse/lib/mentionable-item-search"
      );

      $input.autocomplete({
        template: findRawTemplate("javascripts/mentionable-item-autocomplete"),
        key: SEPARATOR,
        afterComplete: (value) => {
          this.composer.set("reply", value);
          scheduleOnce("afterRender", () => $input.blur().focus());
        },
        transformComplete: (item) => item.model.slug,
        dataSource: (term) =>
          term.match(/\s/) ? null : searchMentionableItem(term, siteSettings),
        triggerRule: (textarea) =>
          !inCodeBlock(textarea.value, caretPosition(textarea)),
      });
    }

    $input.on("scroll", this._throttledSyncEditorAndPreviewScroll);
    this._bindUploadTarget();

    const wizardEventNames = ["insert-text", "replace-text"];
    const eventPrefix = this.eventPrefix;
    this.appEvents.reopen({
      trigger(name, ...args) {
        let eventParts = name.split(":");
        let currentEventPrefix = eventParts[0];
        let currentEventName = eventParts[1];

        if (
          currentEventPrefix !== "wizard-editor" &&
          wizardEventNames.some((wen) => wen === currentEventName)
        ) {
          let wizardEventName = name.replace(eventPrefix, "wizard-editor");
          return this._super(wizardEventName, ...args);
        } else {
          return this._super(name, ...args);
        }
      },
    });
  },

  @discourseComputed("field.id")
  fileUploadElementId(fieldId) {
    return `file-uploader-${dasherize(fieldId)}`;
  },

  @discourseComputed
  allowedFileTypes() {
    return this.siteSettings.authorized_extensions
      .split("|")
      .map((ext) => "." + ext)
      .join(",");
  },

  @discourseComputed()
  uploadIcon() {
    return uploadIcon(false, this.siteSettings);
  },

  click(e) {
    if ($(e.target).hasClass("wizard-composer-hyperlink")) {
      this.set("showHyperlinkBox", false);
    }
  },

  @bind
  _handleImageDeleteButtonClick(event) {
    if (!event.target.classList.contains("delete-image-button")) {
      return;
    }

    const index = parseInt(
      event.target.closest(".button-wrapper").dataset.imageIndex,
      10
    );
    const matchingPlaceholder = this.get("composer.reply").match(
      IMAGE_MARKDOWN_REGEX
    );

    this.session.set("wizardEventFieldId", this.field.id);
    this.appEvents.trigger(
      "composer:replace-text",
      matchingPlaceholder[index],
      "",
      { regex: IMAGE_MARKDOWN_REGEX, index }
    );
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
        sendAction: () => component.set("showHyperlinkBox", true),
      });

      if (this.siteSettings.mentionables_enabled) {
        const { SEPARATOR } = requirejs(
          "discourse/plugins/discourse-mentionables/discourse/lib/discourse-markdown/mentionable-items"
        );

        toolbar.addButton({
          id: "insert-mentionable",
          group: "extras",
          icon: this.siteSettings.mentionables_composer_button_icon,
          title: "mentionables.composer.insert.title",
          perform: () => {
            this.appEvents.trigger("wizard-editor:insert-text", {
              fieldId: this.field.id,
              text: SEPARATOR,
            });
            const $textarea = $(
              document.querySelector(
                `.composer-field.${this.field.id} textarea.d-editor-input`
              )
            );
            $textarea.trigger("keyup.autocomplete");
          },
        });
      }
    },

    previewUpdated(preview) {
      highlightSyntax(preview, this.siteSettings, this.session);

      if (this.siteSettings.mentionables_enabled) {
        const { linkSeenMentionableItems } = requirejs(
          "discourse/plugins/discourse-mentionables/discourse/lib/mentionable-items-preview-styling"
        );
        linkSeenMentionableItems(preview, this.siteSettings);
      }
      this._super(...arguments);
    },

    addLink(linkName, linkUrl) {
      let link = `[${linkName}](${linkUrl})`;
      this.appEvents.trigger("wizard-editor:insert-text", {
        fieldId: this.field.id,
        text: link,
      });
      this.set("showHyperlinkBox", false);
    },

    hideBox() {
      this.set("showHyperlinkBox", false);
    },

    showUploadModal() {
      this.session.set("wizardEventFieldId", this.field.id);
      document.getElementById(this.fileUploadElementId).click();
    },
  },
});
