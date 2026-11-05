import { hash } from "@ember/helper";
import { action, computed } from "@ember/object";
import { service } from "@ember/service";
import { dasherize } from "@ember/string";
import ComposerEditor from "discourse/components/composer-editor";
import UpsertHyperlink from "discourse/components/modal/upsert-hyperlink";
import { bind } from "discourse/lib/decorators";
import { uploadIcon } from "discourse/lib/uploads";
import DEditor from "discourse/ui-kit/d-editor";

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
    this.uppyComposerUpload.composerModel = this.composer.model;
    if (!this.currentUser) {
      this.currentUser = {};
    }
  }

  @computed("topicList.loadingMore")
  get loadingMore() {
    return this.topicList?.loadingMore;
  }

  @bind
  setupEditor(textManipulation) {
    textManipulation.placeholder.composer = this.composer;

    // Core focuses the editor on setup, which would scroll the page past the
    // step's title and description.
    const textarea = textManipulation.textarea;
    if (textarea) {
      const focus = textarea.focus.bind(textarea);
      textarea.focus = (options) => focus({ ...options, preventScroll: true });
    }

    super.setupEditor(textManipulation);
  }

  get allowedFileTypes() {
    return this.siteSettings.authorized_extensions
      .split("|")
      .map((ext) => "." + ext)
      .join(",");
  }

  get uploadIcon() {
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
    this.modal.show(UpsertHyperlink, {
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

  <template>
    <div class={{this.fieldClass}}>
      <DEditor
        @tabindex={{this.field.tabindex}}
        @value={{this.composer.model.reply}}
        @placeholderOverride={{this.replyPlaceholder}}
        @previewUpdated={{this.previewUpdated}}
        @markdownOptions={{this.markdownOptions}}
        @extraButtons={{this.extraButtons}}
        @importQuote={{this.importQuote}}
        @showUploadModal={{this.showUploadModal}}
        @togglePreview={{this.togglePreview}}
        @validation={{this.validation}}
        @loading={{this.composer.loading}}
        @showLink={{this.showLink}}
        @wizardComposer={{true}}
        @fieldId={{this.field.id}}
        @disabled={{this.disableTextarea}}
        @onSetup={{this.setupEditor}}
        @outletArgs={{hash composer=this.composer editorType="composer"}}
      />

      <input
        type="file"
        id={{this.uppyComposerUpload.fileUploadElementId}}
        class="wizard-composer-upload"
        accept={{this.allowedFileTypes}}
        multiple
      />
    </div>
  </template>
}
