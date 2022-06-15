import Component from "@ember/component";
import { dasherize } from "@ember/string";
import discourseComputed from "discourse-common/utils/decorators";
import { cook } from "discourse/plugins/discourse-custom-wizard/wizard/lib/text-lite";

export default Component.extend({
  layoutName: "wizard/templates/components/wizard-field",
  classNameBindings: [
    ":wizard-field",
    "typeClasses",
    "field.invalid",
    "field.id",
  ],

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
    return dasherize(type === "component" ? id : `wizard-field-${type}`);
  },

  @discourseComputed("field.translatedDescription")
  cookedDescription(description) {
    return cook(description);
  },

  @discourseComputed("field.type")
  textType(fieldType) {
    return ["text", "textarea"].includes(fieldType);
  },
});
