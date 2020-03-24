import { alias, equal } from "@ember/object/computed";
import { computed } from "@ember/object";
import {
  default as discourseComputed,
  observes
} from "discourse-common/utils/decorators";
import { defaultSelectionType } from '../lib/custom-wizard'; 

export default Ember.Component.extend({
  classNames: 'input-selector',
  groups: alias('site.groups'),
  categories: computed(function() {
    return this.site.categories.map(c => ({ id: c.id, name: c.name }));
  }),
  
  @observes('options.@each')
  resetActiveType() {
    this.set('activeType', defaultSelectionType(this.selectorType, this.options));
  },
  
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
    return this.activeType === type && this[`${type}Enabled`] && !this[`${type}Disabled`];
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
    
    const types = [this.selectorType, this.inputType];
    
    console.log('running', types, option)

    return option.split(',').filter(o => types.indexOf(o) !== -1).length
  },
  
  textDisabled: computed('options.textDisabled', 'inputType', function() { return this.optionEnabled('textDisabled') }),
  wizardEnabled: computed('options.wizardFieldSelection', 'inputType', function() { return this.optionEnabled('wizardFieldSelection') }),
  userEnabled: computed('options.userFieldSelection', 'inputType', function() { return this.optionEnabled('userFieldSelection') }),
  categoryEnabled: computed('options.categorySelection', 'inputType', function() { return this.optionEnabled('categorySelection') }),
  tagEnabled: computed('options.tagSelection', 'inputType', function() { return this.optionEnabled('tagSelection') }),
  groupEnabled: computed('options.groupSelection', 'inputType', function() { return this.optionEnabled('groupSelection') }),
  
  actions: {
    toggleType(type) {
      this.set('activeType', type);
    }
  }
})