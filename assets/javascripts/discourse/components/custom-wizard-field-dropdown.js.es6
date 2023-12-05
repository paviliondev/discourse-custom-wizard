import Component from "@ember/component";

export default Component.extend({
  keyPress(e) {
    e.stopPropagation();
  },

  actions: {
    onChangeValue(value) {
      this.set("field.value", value);
    },
  },
});
