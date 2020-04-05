import { alias, or } from "@ember/object/computed";
import { computed } from "@ember/object";
import { default as discourseComputed, observes } from "discourse-common/utils/decorators";
import { getOwner } from 'discourse-common/lib/get-owner';
import { defaultSelectionType, selectionTypes } from '../lib/wizard-mapper'; 
import { snakeCase, selectKitContent } from '../lib/wizard';
import Component from "@ember/component";

export default Component.extend({
  classNames: 'mapper-selector',
  groups: alias('site.groups'),
  categories: computed(function() { return selectKitContent(this.site.categories) }),
  showText: computed('activeType', function() { return this.showInput('text') }),
  showWizardField: computed('activeType', function() { return this.showInput('wizardField') }),
  showUserField: computed('activeType', function() { return this.showInput('userField') }),
  showCategory: computed('activeType', function() { return this.showInput('category') }),
  showTag: computed('activeType', function() { return this.showInput('tag') }),
  showGroup: computed('activeType', function() { return this.showInput('group') }),
  showUser: computed('activeType', function() { return this.showInput('user') }),
  showList: computed('activeType', function() { return this.showInput('list') }),
  showComboBox: or('showWizardField', 'showUserField'),
  showMultiSelect: or('showCategory', 'showGroup'),
  textEnabled: computed('options.textSelection', 'inputType', function() { return this.optionEnabled('textSelection') }),
  wizardFieldEnabled: computed('options.wizardFieldSelection', 'inputType', function() { return this.optionEnabled('wizardFieldSelection') }),
  userFieldEnabled: computed('options.userFieldSelection', 'inputType', function() { return this.optionEnabled('userFieldSelection') }),
  categoryEnabled: computed('options.categorySelection', 'inputType', function() { return this.optionEnabled('categorySelection') }),
  tagEnabled: computed('options.tagSelection', 'inputType', function() { return this.optionEnabled('tagSelection') }),
  groupEnabled: computed('options.groupSelection', 'inputType', function() { return this.optionEnabled('groupSelection') }),
  userEnabled: computed('options.userSelection', 'inputType', function() { return this.optionEnabled('userSelection') }),
  listEnabled: computed('options.listSelection', 'inputType', function() { return this.optionEnabled('listSelection') }),
  
  @discourseComputed('activeType')
  selectorTypes(activeType) {
    return selectionTypes.filter(type => (this[`${type}Enabled`]));
  },
  
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
  
  @discourseComputed('activeType')
  comboBoxContent(activeType) {
    return this[`${activeType}Fields`];
  },
  
  @discourseComputed('activeType')
  multiSelectContent(activeType) {
    return {
      category: this.categories,
      group: this.groups,
      list: ''
    }[activeType];
  },
  
  @discourseComputed('activeType')
  placeholder(activeType) {
    if (activeType === 'text' && this.options[`${this.selectorType}Placeholder`]) {
      return this.options[`${this.selectorType}Placeholder`];
    }
    return `admin.wizard.selector.placeholder.${snakeCase(activeType)}`;
  },
  
  @discourseComputed('activeType')
  multiSelectOptions(activeType) {
    let result = {
      none: this.placeholder
    };
    
    if (activeType === 'list') {
      result.allowAny = true;
    }
    
    return result;
  },
  
  optionEnabled(type) {
    const options = this.options;
    if (!options) return false;
    
    const option = options[type];
    if (option === true) return true;
    if (typeof option !== 'string') return false;
        
    return option.split(',').filter(option => {
      return [this.selectorType, this.inputType].indexOf(option) !== -1;
    }).length;
  },
  
  showInput(type) {
    return this.activeType === type && this[`${type}Enabled`];
  },
  
  actions: {
    toggleType(type) {
      this.set('activeType', type);
    }
  }
})