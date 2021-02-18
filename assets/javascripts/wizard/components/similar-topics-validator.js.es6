import WizardFieldValidator from "../../wizard/components/validator";
import { deepMerge } from "discourse-common/lib/object";
import { observes } from "discourse-common/utils/decorators";
import { cancel, later } from "@ember/runloop";
import { A } from "@ember/array";
import EmberObject, { computed } from "@ember/object";
import { notEmpty, and, equal, empty } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import { categoryBadgeHTML } from "discourse/helpers/category-link";

export default WizardFieldValidator.extend({
  classNames: ['similar-topics-validator'],
  similarTopics: null,
  hasInput: notEmpty('field.value'),
  hasSimilarTopics: notEmpty('similarTopics'),
  hasNotSearched: equal('similarTopics', null),
  noSimilarTopics: computed('similarTopics', function() {
    return this.similarTopics !== null && this.similarTopics.length == 0;
  }),
  showDefault: computed('hasNotSearched', 'hasInput', 'typing', function() {
    return this.hasInput && (this.hasNotSearched || this.typing);
  }),
  showSimilarTopics: computed('typing', 'hasSimilarTopics', function() {
    return this.hasSimilarTopics && !this.typing;
  }),
  showNoSimilarTopics: computed('typing', 'noSimilarTopics', function() {
    return this.noSimilarTopics && !this.typing;
  }),
  hasValidationCategories: notEmpty('validationCategories'),
  
  @discourseComputed('validation.categories')
  validationCategories(categoryIds) {
    return categoryIds.map(id => this.site.categoriesById[id]);
  },
  
  @discourseComputed('validationCategories')
  catLinks(categories) {
    return categories.map(category => categoryBadgeHTML(category)).join("");
  },
  
  validate() {},

  @observes("field.value")
  customValidate() {
    const field = this.field;
    
    if (!field.value) return;
    const value = field.value;
    
    this.set("typing", true);
    
    if (value && value.length < 5) {
      this.set('similarTopics', null);
      return;
    }
    
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
      
      this.updateSimilarTopics();
    }, 1000);
  },

  updateSimilarTopics() {
    this.set('updating', true);
    
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
    }).finally(() => this.set('updating', false));
  },

  actions: {
    closeMessage() {
      this.set("showMessage", false);
    },
  },
});
