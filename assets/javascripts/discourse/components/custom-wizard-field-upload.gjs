/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { action, computed } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import UppyUpload from "discourse/lib/uppy/uppy-upload";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class CustomWizardFieldUpload extends Component {
  @service siteSettings;

  @action
  setup() {
    this.uppyUpload = new UppyUpload(this, {
      id: this.inputId,
      type: `wizard_${this.field.id}`,
      uploadDone: (upload) => {
        this.setProperties({
          "field.value": upload,
          isImage: this.imageUploadFormats.includes(upload.extension),
        });
      },
    });
    this.uppyUpload.setup(document.getElementById(this.inputId));
  }

  get imageUploadFormats() {
    return this.siteSettings.wizard_recognised_image_upload_formats.split("|");
  }

  get inputId() {
    return `wizard_field_upload_${this.field?.id}`;
  }

  get wrapperClass() {
    let result = "wizard-field-upload";
    if (this.isImage) {
      result += " is-image";
    }
    if (this.fieldClass) {
      result += ` ${this.fieldClass}`;
    }
    return result;
  }

  @computed("uppyUpload.uploading", "uppyUpload.uploadProgress")
  get uploadLabel() {
    return this.uppyUpload?.uploading
      ? `${i18n("wizard.uploading")} ${this.uppyUpload.uploadProgress}%`
      : i18n("wizard.upload");
  }

  @action
  chooseFiles() {
    this.uppyUpload?.openPicker();
  }

  <template>
    <div class={{this.wrapperClass}}>
      <input
        {{didInsert this.setup}}
        disabled={{this.uppyUpload.uploading}}
        id={{this.inputId}}
        class="hidden-upload-field"
        type="file"
        accept={{this.field.file_types}}
        style="visibility: hidden; position: absolute;"
      />
      <DButton
        @translatedLabel={{this.uploadLabel}}
        @translatedTitle={{this.uploadLabel}}
        @icon="upload"
        @disabled={{this.uppyUpload.uploading}}
        @action={{this.chooseFiles}}
        class="wizard-btn wizard-btn-upload-file"
      />
      {{#if this.field.value}}
        {{#if this.isImage}}
          <img src={{this.field.value.url}} class="wizard-image-preview" />
        {{else}}
          {{this.field.value.original_filename}}
        {{/if}}
      {{/if}}
    </div>
  </template>
}
