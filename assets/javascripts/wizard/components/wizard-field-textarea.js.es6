import Component from "@ember/component";

export default Component.extend({
  layoutName: "wizard/templates/components/wizard-field-textarea",

  keyPress(e) {
    e.stopPropagation();
  },
});
