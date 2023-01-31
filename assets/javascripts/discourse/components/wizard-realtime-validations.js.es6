import Component from "@ember/component";
import EmberObject from "@ember/object";
import { cloneJSON } from "discourse-common/lib/object";
import Category from "discourse/models/category";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend({
  classNames: ["realtime-validations", "setting", "full", "subscription"],

  @discourseComputed
  timeUnits() {
    return ["days", "weeks", "months", "years"].map((unit) => {
      return {
        id: unit,
        name: I18n.t(`admin.wizard.field.validations.time_units.${unit}`),
      };
    });
  },

  init() {
    this._super(...arguments);
    if (!this.validations) {
      return;
    }

    if (!this.field.validations) {
      const validations = {};

      this.validations.forEach((validation) => {
        validations[validation] = {};
      });

      this.set("field.validations", EmberObject.create(validations));
    }

    const validationBuffer = cloneJSON(this.get("field.validations"));
    let bufferCategories;
    if (
      validationBuffer.similar_topics &&
      (bufferCategories = validationBuffer.similar_topics.categories)
    ) {
      const categories = Category.findByIds(bufferCategories);
      validationBuffer.similar_topics.categories = categories;
    }
    this.set("validationBuffer", validationBuffer);
  },

  actions: {
    updateValidationCategories(type, validation, categories) {
      this.set(`validationBuffer.${type}.categories`, categories);
      this.set(
        `field.validations.${type}.categories`,
        categories.map((category) => category.id)
      );
    },
  },
});
