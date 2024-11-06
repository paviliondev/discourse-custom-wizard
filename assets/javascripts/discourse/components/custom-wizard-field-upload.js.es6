import UppyUpload from "discourse/lib/uppy/uppy-upload";
import Component from "@ember/component";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "discourse-i18n";
import { action } from "@ember/object";

export default class CustomWizardFieldUpload extends Component {
  @service siteSettings;

  @action
  setup() {
    this.uppyUpload = new UppyUpload(getOwner(this), {
      id: this.inputId,
      type: `wizard_${this.field.id}`,
      uploadDone: (upload) => {
        this.setProperties({
          "field.value": upload,
          isImage: this.imageUploadFormats.includes(upload.extension),
        });
        this.done();
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

  @discourseComputed("uppyUpload.uploading", "uppyUpload.uploadProgress")
  uploadLabel() {
    return this.uppyUpload?.uploading
      ? `${I18n.t("wizard.uploading")} ${this.uppyUpload.uploadProgress}%`
      : I18n.t("wizard.upload");
  }

  @action
  chooseFiles() {
    this.uppyUpload?.openPicker();
  }
}
