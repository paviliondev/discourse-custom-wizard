import Component from "@ember/component";

export default Component.extend({
  classNames: "wizard-custom-step",

  actions: {
    bannerUploadDone(upload) {
      this.set("step.banner", upload.url);
    },

    bannerUploadDeleted() {
      this.set("step.banner", null);
    },
  },
});
