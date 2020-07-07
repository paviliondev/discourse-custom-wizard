import getUrl from "discourse-common/lib/get-url";
import { getToken } from "wizard/lib/ajax";
import I18n from "I18n";

export default Ember.Component.extend({
  classNames: ["wizard-field-upload"],
  classNameBindings: ["isImage"],
  uploading: false,
  isImage: false,

  didInsertElement() {
    this._super();

    const $upload = $(this.element);

    const id = this.get("field.id");

    $upload.fileupload({
      url: getUrl("/uploads.json"),
      formData: {
        synchronous: true,
        type: `wizard_${id}`,
        authenticity_token: getToken()
      },
      dataType: "json",
      dropZone: $upload
    });

    $upload.on("fileuploadsubmit", () => this.set("uploading", true));

    $upload.on("fileuploaddone", (e, response) => {
      this.setProperties({
        "field.value": response.result,
        "uploading": false
      });
      if ( Discourse.SiteSettings.wizard_recognised_image_upload_formats.split('|').includes(response.result.extension)) {
        this.setProperties({
          "isImage": true
        })
      }
    });

    $upload.on("fileuploadfail", (e, response) => {
      let message = I18n.t("wizard.upload_error");
      if (response.jqXHR.responseJSON && response.jqXHR.responseJSON.errors) {
        message = response.jqXHR.responseJSON.errors.join("\n");
      }

      window.swal({
        customClass: "wizard-warning",
        title: "",
        text: message,
        type: "warning",
        confirmButtonColor: "#6699ff"
      });
      this.set("uploading", false);
    });
  }
});
