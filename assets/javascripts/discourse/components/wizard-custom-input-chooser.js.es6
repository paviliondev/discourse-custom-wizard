import { alias, equal } from "@ember/object/computed";
import { computed } from "@ember/object";
import {
  default as discourseComputed,
  observes
} from "discourse-common/utils/decorators";

export default Ember.Component.extend({
  @observes('activeType')
  clearValue() {
    this.set('value', null);
  },

  @discourseComputed('customPlaceholder')
  textPlaceholder(customPlaceholder) {
    return customPlaceholder || 'admin.wizard.text';
  },
  
  @discourseComputed('activeType', 'userEnabled')
  showUser(activeType, userEnabled) {
    return activeType === 'user' && userEnabled;
  },
  
  @discourseComputed('activeType', 'wizardEnabled')
  showWizard(activeType, wizardEnabled) {
    return activeType === 'wizard' && wizardEnabled;
  },
  
  showText: equal('activeType', 'text'),
  
  @discourseComputed('options.allowWizardField', 'inputType')
  wizardEnabled(allowWizardField, inputType) {
    return allowWizardField === true || allowWizardField === inputType;
  },
  
  @discourseComputed('options.allowUserField', 'inputType')
  userEnabled(allowUserField, inputType) {
    return allowUserField === true || allowUserField === inputType;
  },
  
  actions: {
    toggleType(type) {
      this.set('activeType', type);
    }
  }
})