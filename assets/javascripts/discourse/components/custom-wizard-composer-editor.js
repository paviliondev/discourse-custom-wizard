import ComposerEditor from "discourse/components/composer-editor";
import discourseComputed, { bind } from "discourse-common/utils/decorators";
import { alias } from "@ember/object/computed";
import { uploadIcon } from "discourse/lib/uploads";
import { dasherize } from "@ember/string";
import InsertHyperlink from "discourse/components/modal/insert-hyperlink";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export const wizardComposerEdtiorEventPrefix = "wizard-editor";

export default class CustomWizardComposerEditor extends ComposerEditor {
  @service modal;
  allowUpload = true;
  showLink = false;
  topic = null;
  showToolbar = true;
  focusTarget = "reply";
  canWhisper = false;
  lastValidatedAt = "lastValidatedAt";
  popupMenuOptions = [];
  draftStatus = "null";
  @alias("topicList.loadingMore") loadingMore;
  wizardEventFieldId = null;
  composerEventPrefix = wizardComposerEdtiorEventPrefix;

  init() {
    super.init(...arguments);
    this.uppyComposerUpload.fileUploadElementId = `file-uploader-${dasherize(
      this.field.id
    )}`;
    this.uppyComposerUpload.editorInputClass = `.${dasherize(
      this.field.type
    )}-${dasherize(this.field.id)} .d-editor-input`;
    this.uppyComposerUpload.composerModel = this.composer;
    if (!this.currentUser) {
      this.currentUser = {};
    }
  }

  @discourseComputed
  allowedFileTypes() {
    return this.siteSettings.authorized_extensions
      .split("|")
      .map((ext) => "." + ext)
      .join(",");
  }

  @discourseComputed()
  uploadIcon() {
    return uploadIcon(false, this.siteSettings);
  }

  @bind
  _handleImageDeleteButtonClick() {
    this.session.set("wizardEventFieldId", this.field.id);
    super._handleImageDeleteButtonClick(...arguments);
  }

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
  }

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
  }

  @action
  showUploadModal() {
    this.session.set("wizardEventFieldId", this.field.id);
    document
      .getElementById(this.uppyComposerUpload.fileUploadElementId)
      .click();
  }

  _uploadDropTargetOptions() {
    return {
      target: this.element,
      onDrop: () => {
        this.session.set("wizardEventFieldId", this.field.id);
      },
    };
  }
}
