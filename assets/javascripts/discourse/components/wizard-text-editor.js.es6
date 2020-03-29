import { default as discourseComputed } from 'discourse-common/utils/decorators';
import { profileFields } from '../lib/custom-wizard';

export default Ember.Component.extend({
  classNames: 'wizard-text-editor',
  
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
  userFieldList() {
    return profileFields.map((f) => ` u{${f}}`);
  },
  
  @discourseComputed('wizardFields')
  wizardFieldList(wizardFields) {
    return wizardFields.map((f) => ` w{${f.id}}`);
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