import Component from "@ember/component";
import { not, notEmpty } from "@ember/object/computed";
import { default as discourseComputed } from "discourse-common/utils/decorators";
import I18n from "I18n";

const icons = {
  error: "circle-xmark",
  success: "circle-check",
  warn: "exclamation-circle",
  info: "circle-info",
};

export default Component.extend({
  classNameBindings: [":wizard-message", "type", "loading"],
  showDocumentation: not("loading"),
  showIcon: not("loading"),
  hasItems: notEmpty("items"),

  @discourseComputed("type")
  icon(type) {
    return icons[type] || "circle-info";
  },

  @discourseComputed("key", "component", "opts")
  message(key, component, opts) {
    return I18n.t(`admin.wizard.message.${component}.${key}`, opts || {});
  },

  @discourseComputed("component")
  documentation(component) {
    return I18n.t(`admin.wizard.message.${component}.documentation`);
  },
});
