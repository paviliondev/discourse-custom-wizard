import getUrl from "discourse-common/lib/get-url";
import { getToken } from "wizard/lib/ajax";
import WizardI18n from "../lib/wizard-i18n";
import Uppy from "@uppy/core";
import DropTarget from "@uppy/drop-target";
import XHRUpload from "@uppy/xhr-upload";

export default Ember.Component.extend({
  classNames: ["wizard-field-upload"],
  classNameBindings: ["isImage"],
  uploading: false,
  isImage: false,

  didInsertElement() {
    this._super(...arguments);
    this.setupUploads();
  },

  setupUploads() {
    const id = this.get("field.id");
    this._uppyInstance = new Uppy({
      id: `wizard-field-image-${id}`,
      meta: { upload_type: `wizard_${id}` },
      autoProceed: true,
    });

    this._uppyInstance.use(XHRUpload, {
      endpoint: getUrl("/uploads.json"),
      headers: {
        "X-CSRF-Token": getToken(),
      },
    });

    this._uppyInstance.use(DropTarget, { target: this.element });

    this._uppyInstance.on("upload", () => {
      this.set("uploading", true);
    });

    this._uppyInstance.on("upload-success", (file, response) => {
      this.set("field.value", response.body);
      this.set("uploading", false);
      if (
        Discourse.SiteSettings.wizard_recognised_image_upload_formats
          .split("|")
          .includes(response.body.extension)
      ) {
        this.setProperties({
          isImage: true,
        });
      }
    });

    this._uppyInstance.on("upload-error", (file, error, response) => {
      let message = WizardI18n("wizard.upload_error");
      if (response.body.errors) {
        message = response.body.errors.join("\n");
      }

      window.swal({
        customClass: "wizard-warning",
        title: "",
        text: message,
        type: "warning",
        confirmButtonColor: "#6699ff",
      });
      this.set("uploading", false);
    });

    this.element
      .querySelector(".wizard-hidden-upload-field")
      .addEventListener("change", (event) => {
        const files = Array.from(event.target.files);
        files.forEach((file) => {
          try {
            this._uppyInstance.addFile({
              source: `${this.id} file input`,
              name: file.name,
              type: file.type,
              data: file,
            });
          } catch (err) {
            warn(`error adding files to uppy: ${err}`, {
              id: "discourse.upload.uppy-add-files-error",
            });
          }
        });
      });
  },
});
