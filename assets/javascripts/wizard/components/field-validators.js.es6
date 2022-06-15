import Component from "@ember/component";

export default Component.extend({
  layoutName: "wizard/templates/components/field-validators",

  actions: {
    perform() {
      this.appEvents.trigger("custom-wizard:validate");
    },
  },
});
