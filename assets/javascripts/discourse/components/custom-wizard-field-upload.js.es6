import UppyUploadMixin from "discourse/mixins/uppy-upload";
import Component from "@ember/component";
import { computed } from "@ember/object";

export default Component.extend(UppyUploadMixin, {
  classNames: ["wizard-field-upload"],
  classNameBindings: ["isImage"],
  uploading: false,
  type: computed(function () {
    return `wizard_${this.field.id}`;
  }),
  id: computed(function () {
    return `wizard_field_upload_${this.field.id}`;
  }),
  isImage: computed("field.value.extension", function () {
    return (
      this.field.value &&
      this.siteSettings.wizard_recognised_image_upload_formats
        .split("|")
        .includes(this.field.value.extension)
    );
  }),

  uploadDone(upload) {
    this.set("field.value", upload);
  },
});
