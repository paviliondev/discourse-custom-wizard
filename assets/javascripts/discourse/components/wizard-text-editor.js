import Component from "@ember/component";
import { notEmpty } from "@ember/object/computed";
import { scheduleOnce } from "@ember/runloop";
import $ from "jquery";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import { userProperties } from "../lib/wizard";

const excludedUserProperties = ["profile_background", "card_background"];

export default Component.extend({
  classNames: "wizard-text-editor",
  barEnabled: true,
  previewEnabled: true,
  fieldsEnabled: true,
  hasWizardFields: notEmpty("wizardFieldList"),
  hasWizardActions: notEmpty("wizardActionList"),

  didReceiveAttrs() {
    this._super(...arguments);

    if (!this.barEnabled) {
      scheduleOnce("afterRender", this, this._hideButtonBar);
    }
  },

  _hideButtonBar() {
    $(this.element).find(".d-editor-button-bar").addClass("hidden");
  },

  @discourseComputed("forcePreview")
  previewLabel(forcePreview) {
    return I18n.t("admin.wizard.editor.preview", {
      action: I18n.t(`admin.wizard.editor.${forcePreview ? "hide" : "show"}`),
    });
  },

  @discourseComputed("showPopover")
  popoverLabel(showPopover) {
    return I18n.t("admin.wizard.editor.popover", {
      action: I18n.t(`admin.wizard.editor.${showPopover ? "hide" : "show"}`),
    });
  },

  @discourseComputed()
  userPropertyList() {
    return userProperties
      .filter((f) => !excludedUserProperties.includes(f))
      .map((f) => ` u{${f}}`);
  },

  @discourseComputed("wizardFields")
  wizardFieldList(wizardFields) {
    return (wizardFields || []).map((f) => ` w{${f.id}}`);
  },

  @discourseComputed("wizardActions")
  wizardActionList(wizardActions) {
    return (wizardActions || []).map((a) => ` w{${a.id}}`);
  },

  actions: {
    togglePreview() {
      this.toggleProperty("forcePreview");
    },

    togglePopover() {
      this.toggleProperty("showPopover");
    },
  },
});
