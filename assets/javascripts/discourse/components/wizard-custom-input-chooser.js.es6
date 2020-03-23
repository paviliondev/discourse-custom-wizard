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
  
  showText: equal('activeType', 'text'),
  
  showInput(type) {
    return this.activeType === type && this[`${type}Enabled`];
  },
  
  showWizard: computed('activeType', function() { return this.showInput('wizard') }),
  showUser: computed('activeType', function() { return this.showInput('user') }),
  showCategory: computed('activeType', function() { return this.showInput('category') }),
  showTag: computed('activeType', function() { return this.showInput('tag') }),
  showGroup: computed('activeType', function() { return this.showInput('group') }),
  
  optionEnabled(type) {
    const options = this.options;
    if (!options) return false;
    
    const option = options[type];
    if (option === true) return true;
    if (typeof option !== 'string') return false;
    return option.split(',').indexOf(this.inputType) > -1;
  },
  
  wizardEnabled: computed('options.allowWizard', function() { return this.optionEnabled('allowWizard') }),
  userEnabled: computed('options.allowUser', function() { return this.optionEnabled('allowUser') }),
  categoryEnabled: computed('options.allowCategory', function() { return this.optionEnabled('allowCategory') }),
  tagEnabled: computed('options.allowTag', function() { return this.optionEnabled('allowTag') }),
  groupEnabled: computed('options.allowGroup', function() { return this.optionEnabled('allowGroup') }),
  
  actions: {
    toggleType(type) {
      this.set('activeType', type);
    }
  }
})