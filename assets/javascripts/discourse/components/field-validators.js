import Component from "@ember/component";

export default Component.extend({
  actions: {
    perform() {
      this.appEvents.trigger("custom-wizard:validate");
    },
  },
});
