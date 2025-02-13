import Component from "@ember/component";
import EmberObject, { action } from "@ember/object";
import {
  default as computed,
  observes,
} from "discourse-common/utils/decorators";

export default Component.extend({
  showPreview: false,
  classNameBindings: [
    ":wizard-field-composer",
    "showPreview:show-preview:hide-preview",
  ],

  init() {
    this._super(...arguments);
    this.set(
      "composer",
      EmberObject.create({
        loading: false,
        model: {
          reply: this.get("field.value") || "",
        },
        afterRefresh: () => {},
        allowUpload: true
      })
    );
  },

  @observes("composer.model.reply")
  setField() {
    this.set("field.value", this.get("composer.model.reply"));
  },

  @computed("showPreview")
  togglePreviewLabel(showPreview) {
    return showPreview
      ? "wizard_composer.hide_preview"
      : "wizard_composer.show_preview";
  },

  @action
  importQuote() {},

  @action
  groupsMentioned() {},

  @action
  afterRefresh() {},

  @action
  cannotSeeMention() {},

  @action
  showUploadSelector() {},

  @action
  togglePreview() {
    this.toggleProperty("showPreview");
  },
});
