import WizardFieldValidator from "discourse/plugins/discourse-custom-wizard/discourse/components/validator";
import { deepMerge } from "discourse-common/lib/object";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import { cancel, later } from "@ember/runloop";
import { A } from "@ember/array";
import EmberObject, { computed } from "@ember/object";
import { and, equal, notEmpty } from "@ember/object/computed";
import { categoryBadgeHTML } from "discourse/helpers/category-link";
import { dasherize } from "@ember/string";

export default WizardFieldValidator.extend({
  classNames: ["similar-topics-validator"],
  similarTopics: null,
  hasInput: notEmpty("field.value"),
  hasSimilarTopics: notEmpty("similarTopics"),
  hasNotSearched: equal("similarTopics", null),
  noSimilarTopics: computed("similarTopics", function () {
    return this.similarTopics !== null && this.similarTopics.length === 0;
  }),
  showSimilarTopics: computed("typing", "hasSimilarTopics", function () {
    return this.hasSimilarTopics && !this.typing;
  }),
  showNoSimilarTopics: computed("typing", "noSimilarTopics", function () {
    return this.noSimilarTopics && !this.typing;
  }),
  hasValidationCategories: notEmpty("validationCategories"),
  insufficientCharacters: computed("typing", "field.value", function () {
    return this.hasInput && this.field.value.length < 5 && !this.typing;
  }),
  insufficientCharactersCategories: and(
    "insufficientCharacters",
    "hasValidationCategories"
  ),

  @discourseComputed("validation.categories")
  validationCategories(categoryIds) {
    if (categoryIds) {
      return categoryIds.map((id) => this.site.categoriesById[id]);
    }

    return A();
  },

  @discourseComputed("validationCategories")
  catLinks(categories) {
    return categories.map((category) => categoryBadgeHTML(category)).join("");
  },

  @discourseComputed(
    "loading",
    "showSimilarTopics",
    "showNoSimilarTopics",
    "insufficientCharacters",
    "insufficientCharactersCategories"
  )
  currentState(
    loading,
    showSimilarTopics,
    showNoSimilarTopics,
    insufficientCharacters,
    insufficientCharactersCategories
  ) {
    switch (true) {
      case loading:
        return "loading";
      case showSimilarTopics:
        return "results";
      case showNoSimilarTopics:
        return "no_results";
      case insufficientCharactersCategories:
        return "insufficient_characters_categories";
      case insufficientCharacters:
        return "insufficient_characters";
      default:
        return false;
    }
  },

  @discourseComputed("currentState")
  currentStateClass(currentState) {
    if (currentState) {
      return `similar-topics-${dasherize(currentState)}`;
    }

    return "similar-topics";
  },

  @discourseComputed("currentState")
  currentStateKey(currentState) {
    if (currentState) {
      return `realtime_validations.similar_topics.${currentState}`;
    }

    return false;
  },

  validate() {},

  @observes("field.value")
  customValidate() {
    const field = this.field;

    if (!field.value) {
      this.set("similarTopics", null);
      return;
    }
    const value = field.value;

    this.set("typing", true);

    const lastKeyUp = new Date();
    this._lastKeyUp = lastKeyUp;

    // One second from now, check to see if the last key was hit when
    // we recorded it. If it was, the user paused typing.
    cancel(this._lastKeyTimeout);
    this._lastKeyTimeout = later(() => {
      if (lastKeyUp !== this._lastKeyUp) {
        return;
      }
      this.set("typing", false);

      if (value && value.length < 5) {
        this.set("similarTopics", null);
        return;
      }

      this.updateSimilarTopics();
    }, 1000);
  },

  updateSimilarTopics() {
    this.set("similarTopics", null);
    this.set("updating", true);

    this.backendValidate({
      title: this.get("field.value"),
      categories: this.get("validation.categories"),
      time_unit: this.get("validation.time_unit"),
      time_n_value: this.get("validation.time_n_value"),
    })
      .then((result) => {
        const similarTopics = A(
          deepMerge(result["topics"], result["similar_topics"])
        );
        similarTopics.forEach(function (topic, index) {
          similarTopics[index] = EmberObject.create(topic);
        });

        this.set("similarTopics", similarTopics);
      })
      .finally(() => this.set("updating", false));
  },

  actions: {
    closeMessage() {
      this.set("showMessage", false);
    },
  },
});
