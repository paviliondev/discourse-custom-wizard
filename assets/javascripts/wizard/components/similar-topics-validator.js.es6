import WizardFieldValidator from "../../wizard/components/validator";
import { deepMerge } from "discourse-common/lib/object";
import { observes } from "discourse-common/utils/decorators";
import { cancel, later } from "@ember/runloop";
import { A } from "@ember/array";
import EmberObject from "@ember/object";

export default WizardFieldValidator.extend({
  similarTopics: [],

  validate() {},

  @observes("field.value")
  customValidate() {
    const lastKeyUp = new Date();
    this._lastKeyUp = lastKeyUp;

    // One second from now, check to see if the last key was hit when
    // we recorded it. If it was, the user paused typing.
    cancel(this._lastKeyTimeout);
    this._lastKeyTimeout = later(() => {
      if (lastKeyUp !== this._lastKeyUp) {
        return;
      }

      this.updateSimilarTopics();
    }, 1000);
  },

  updateSimilarTopics() {
    this.backendValidate({
      title: this.get("field.value"),
      categories: this.get("validation.categories"),
      date_after: this.get("validation.date_after"),
    }).then((result) => {
      const similarTopics = A(
        deepMerge(result["topics"], result["similar_topics"])
      );
      similarTopics.forEach(function (topic, index) {
        similarTopics[index] = EmberObject.create(topic);
      });

      this.set("similarTopics", similarTopics);
    });
  },

  actions: {
    closeMessage() {
      this.set("showMessage", false);
    },
  },
});
