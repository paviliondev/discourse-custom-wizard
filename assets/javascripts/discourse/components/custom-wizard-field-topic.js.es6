import Component from "@ember/component";

export default Component.extend({
  topics: [],

  didInsertElement() {
    const value = this.field.value;

    if (value) {
      this.set("topics", value);
    }
  },

  actions: {
    setValue(_, topics) {
      if (topics.length) {
        this.set("field.value", topics);
      }
    },
  },
});
