import Component from "@ember/component";
import { dasherize } from "@ember/string";
import discourseComputed from "discourse-common/utils/decorators";
import { cookAsync } from "discourse/lib/text";

export default Component.extend({
  classNameBindings: [
    ":wizard-field",
    "typeClasses",
    "field.invalid",
    "field.id",
  ],

  didReceiveAttrs() {
    this._super(...arguments);

    cookAsync(this.field.translatedDescription).then((cookedDescription) => {
      this.set("cookedDescription", cookedDescription);
    });
  },

  @discourseComputed("field.type", "field.id")
  typeClasses: (type, id) =>
    `${dasherize(type)}-field ${dasherize(type)}-${dasherize(id)}`,

  @discourseComputed("field.id")
  fieldClass: (id) => `field-${dasherize(id)} wizard-focusable`,

  @discourseComputed("field.type", "field.id")
  inputComponentName(type, id) {
    if (["text_only"].includes(type)) {
      return false;
    }
    return dasherize(type === "component" ? id : `custom-wizard-field-${type}`);
  },

  @discourseComputed("field.type")
  textType(fieldType) {
    return ["text", "textarea"].includes(fieldType);
  },
});
