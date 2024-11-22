import Component from "@ember/component";
import { bind } from "@ember/runloop";
import $ from "jquery";
import { observes } from "discourse-common/utils/decorators";

export default Component.extend({
  classNames: ["wizard-similar-topics"],
  showTopics: true,

  didInsertElement() {
    this._super(...arguments);
    $(document).on("click", bind(this, this.documentClick));
  },

  willDestroyElement() {
    this._super(...arguments);
    $(document).off("click", bind(this, this.documentClick));
  },

  documentClick(e) {
    if (this._state === "destroying") {
      return;
    }
    let $target = $(e.target);

    if (!$target.hasClass("show-topics")) {
      this.set("showTopics", false);
    }
  },

  @observes("topics")
  toggleShowWhenTopicsChange() {
    this.set("showTopics", true);
  },

  actions: {
    toggleShowTopics() {
      this.set("showTopics", true);
    },
  },
});
