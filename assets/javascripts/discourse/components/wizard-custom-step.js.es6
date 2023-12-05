import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  classNames: "wizard-custom-step",

  @discourseComputed("step.index")
  stepConditionOptions(stepIndex) {
    const options = {
      inputTypes: "validation",
      context: "step",
      textSelection: "value",
      userFieldSelection: true,
      groupSelection: true,
    };

    if (stepIndex > 0) {
      options["wizardFieldSelection"] = true;
      options["wizardActionSelection"] = true;
    }

    return options;
  },

  actions: {
    bannerUploadDone(upload) {
      this.setProperties({
        "step.banner": upload.url,
        "step.banner_upload_id": upload.id,
      });
    },

    bannerUploadDeleted() {
      this.setProperties({
        "step.banner": null,
        "step.banner_upload_id": null,
      });
    },
  },
});
