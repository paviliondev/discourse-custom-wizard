import {
  default as computed,
  observes,
} from "discourse-common/utils/decorators";
import EmberObject from "@ember/object";
import Component from "@ember/component";
import { inject as service } from "@ember/service";

export default Component.extend({
  showPreview: false,
  composer: service(),
  classNameBindings: [
    ":wizard-field-composer",
    "showPreview:show-preview:hide-preview",
  ],

  didInsertElement() {
    debugger;
    this.set("composer.reply", this.get("field.value") || "");
    // this.set(
    //   "composer",
    //   EmberObject.create({
    //     loading: false,
    //     reply: this.get("field.value") || "",
    //   })
    // );
  },

  @observes("composer.reply")
  setField() {
    this.set("field.value", this.get("composer.reply"));
  },

  @computed("showPreview")
  togglePreviewLabel(showPreview) {
    return showPreview
      ? "wizard_composer.hide_preview"
      : "wizard_composer.show_preview";
  },

  actions: {
    togglePreview() {
      this.toggleProperty("showPreview");
    },

    groupsMentioned() {},
    afterRefresh() {},
    cannotSeeMention() {},
    importQuote() {},
    showUploadSelector() {},
  },
});
