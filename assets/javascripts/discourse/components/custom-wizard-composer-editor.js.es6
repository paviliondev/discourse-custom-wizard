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
import InsertHyperlink from "discourse/components/modal/insert-hyperlink";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

const IMAGE_MARKDOWN_REGEX =
  /!\[(.*?)\|(\d{1,4}x\d{1,4})(,\s*\d{1,3}%)?(.*?)\]\((upload:\/\/.*?)\)(?!(.*`))/g;

export const wizardComposerEdtiorEventPrefix = "wizard-editor";

export default ComposerEditor.extend({
  modal: service(),

  classNameBindings: ["fieldClass"],
  allowUpload: true,
  showLink: false,
  topic: null,
  showToolbar: true,
  focusTarget: "reply",
  canWhisper: false,
  lastValidatedAt: "lastValidatedAt",
  popupMenuOptions: [],
  draftStatus: "null",
  replyPlaceholder: alias("field.translatedPlaceholder"),
  wizardEventFieldId: null,
  composerEventPrefix: wizardComposerEdtiorEventPrefix,

  @on("didInsertElement")
  _composerEditorInit() {
    this._super(...arguments);

    if (this.siteSettings.mentionables_enabled) {
      const $input = $(this.element.querySelector(".d-editor-input"));

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
          term.match(/\s/)
            ? null
            : searchMentionableItem(term, this.siteSettings),
        triggerRule: (textarea) =>
          !inCodeBlock(textarea.value, caretPosition(textarea)),
      });
    }

    const field = this.field;
    this.editorInputClass = `.${dasherize(field.type)}-${dasherize(
      field.id
    )} .d-editor-input`;

    this._uppyInstance.on("file-added", () => {
      this.session.set("wizardEventFieldId", field.id);
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

  @bind
  _handleImageDeleteButtonClick(event) {
    if (!event.target.classList.contains("delete-image-button")) {
      return;
    }

    const index = parseInt(
      event.target.closest(".button-wrapper").dataset.imageIndex,
      10
    );
    const matchingPlaceholder =
      this.get("composer.reply").match(IMAGE_MARKDOWN_REGEX);

    this.session.set("wizardEventFieldId", this.field.id);
    this.appEvents.trigger(
      "composer:replace-text",
      matchingPlaceholder[index],
      "",
      { regex: IMAGE_MARKDOWN_REGEX, index }
    );
  },

  @action
  extraButtons(toolbar) {
    const component = this;

    if (this.allowUpload && this.uploadIcon) {
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
      icon: "link",
      group: "insertions",
      shortcut: "K",
      trimLeading: true,
      unshift: true,
      sendAction: (event) => component.send("showLinkModal", event),
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

  @action
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

  @action
  showLinkModal(toolbarEvent) {
    let linkText = "";
    this._lastSel = toolbarEvent.selected;

    if (this._lastSel) {
      linkText = this._lastSel.value;
    }
    this.modal.show(InsertHyperlink, {
      model: { linkText, toolbarEvent },
    });
  },

  @action
  showUploadModal() {
    this.session.set("wizardEventFieldId", this.field.id);
    document.getElementById(this.fileUploadElementId).click();
  },
});
