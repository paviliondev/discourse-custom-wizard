import { default as discourseComputed, on } from 'discourse-common/utils/decorators';
import { notEmpty } from "@ember/object/computed";
import { userProperties } from '../lib/wizard';
import { scheduleOnce } from "@ember/runloop";
import Component from "@ember/component";
import I18n from "I18n";

export default Component.extend({
  classNames: 'wizard-text-editor',
  barEnabled: true,
  previewEnabled: true,
  fieldsEnabled: true,
  hasWizardFields: notEmpty('wizardFieldList'),
  hasWizardActions: notEmpty('wizardActionList'),
  
  didReceiveAttrs() {
    this._super(...arguments);
    
    if (!this.barEnabled) {
      scheduleOnce('afterRender', () => {
        $(this.element).find('.d-editor-button-bar').addClass('hidden');
      });
    }
  },
  
  @discourseComputed('forcePreview')
  previewLabel(forcePreview) {
    return I18n.t("admin.wizard.editor.preview", {
      action: I18n.t(`admin.wizard.editor.${forcePreview ? 'hide' : 'show'}`)
    });
  },
  
  @discourseComputed('showPopover')
  popoverLabel(showPopover) {
    return I18n.t("admin.wizard.editor.popover", {
      action: I18n.t(`admin.wizard.editor.${showPopover ? 'hide' : 'show'}`)
    });
  },
  
  @discourseComputed()
  userPropertyList() {
    return userProperties.map((f) => ` u{${f}}`);
  },
  
  @discourseComputed('wizardFields')
  wizardFieldList(wizardFields) {
    return wizardFields.map((f) => ` w{${f.id}}`);
  },
  
  @discourseComputed('wizardActions')
  wizardActionList(wizardActions) {
    return wizardActions.map((a) => ` w{${a.id}}`);
  },
  
  actions: {
    togglePreview() {
      this.toggleProperty('forcePreview');
    },
    
    togglePopover() {
      this.toggleProperty('showPopover');
    }
  }
});