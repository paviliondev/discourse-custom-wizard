import { alias } from "@ember/object/computed";
import { computed } from "@ember/object";
import { default as discourseComputed, observes } from "discourse-common/utils/decorators";
import { getOwner } from 'discourse-common/lib/get-owner';
import { defaultSelectionType } from '../lib/wizard-mapper'; 

export default Ember.Component.extend({
  classNames: 'mapper-selector',
  groups: alias('site.groups'),
  categories: computed(function() {
    return this.site.categories.map(c => ({ id: c.id, name: c.name }));
  }),
  
  @discourseComputed
  userFields() {
    const controller = getOwner(this).lookup('controller:admin-wizard');
    return controller.model.userFields;
  },
  
  @discourseComputed
  wizardFields() {
    const controller = getOwner(this).lookup('controller:admin-wizard');
    return controller.wizardFields;
  },
  
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
  
  showInput(type) {
    return this.activeType === type && this[`${type}Enabled`];
  },
  
  showText: computed('activeType', function() { return this.showInput('text') }),
  showWizard: computed('activeType', function() { return this.showInput('wizard') }),
  showUserField: computed('activeType', function() { return this.showInput('userField') }),
  showCategory: computed('activeType', function() { return this.showInput('category') }),
  showTag: computed('activeType', function() { return this.showInput('tag') }),
  showGroup: computed('activeType', function() { return this.showInput('group') }),
  showUser: computed('activeType', function() { return this.showInput('user') }),
  
  optionEnabled(type) {
    const options = this.options;
    if (!options) return false;
    
    const option = options[type];
    if (option === true) return true;
    if (typeof option !== 'string') return false;
    
    const types = [this.selectorType, this.inputType];
    
    return option.split(',').filter(o => types.indexOf(o) !== -1).length
  },
  
  textEnabled: computed('options.textSelection', 'inputType', function() { return this.optionEnabled('textSelection') }),
  wizardEnabled: computed('options.wizardSelection', 'inputType', function() { return this.optionEnabled('wizardSelection') }),
  userFieldEnabled: computed('options.userFieldSelection', 'inputType', function() { return this.optionEnabled('userFieldSelection') }),
  categoryEnabled: computed('options.categorySelection', 'inputType', function() { return this.optionEnabled('categorySelection') }),
  tagEnabled: computed('options.tagSelection', 'inputType', function() { return this.optionEnabled('tagSelection') }),
  groupEnabled: computed('options.groupSelection', 'inputType', function() { return this.optionEnabled('groupSelection') }),
  userEnabled: computed('options.userSelection', 'inputType', function() { return this.optionEnabled('userSelection') }),
  
  actions: {
    toggleType(type) {
      this.set('activeType', type);
    }
  }
})