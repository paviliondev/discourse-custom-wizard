import { alias, or, gt } from "@ember/object/computed";
import { computed } from "@ember/object";
import { default as discourseComputed, observes, on } from "discourse-common/utils/decorators";
import { getOwner } from 'discourse-common/lib/get-owner';
import { defaultSelectionType, selectionTypes } from '../lib/wizard-mapper';
import { snakeCase, generateName, userProperties } from '../lib/wizard';
import Component from "@ember/component";
import { bind, later } from "@ember/runloop";
import I18n from "I18n";

export default Component.extend({
  classNameBindings: [':mapper-selector', 'activeType'],
  
  showText: computed('activeType', function() { return this.showInput('text') }),
  showWizardField: computed('activeType', function() { return this.showInput('wizardField') }),
  showWizardAction: computed('activeType', function() { return this.showInput('wizardAction') }),
  showUserField: computed('activeType', function() { return this.showInput('userField') }),
  showUserFieldOptions: computed('activeType', function() { return this.showInput('userFieldOptions') }),
  showCategory: computed('activeType', function() { return this.showInput('category') }),
  showTag: computed('activeType', function() { return this.showInput('tag') }),
  showGroup: computed('activeType', function() { return this.showInput('group') }),
  showUser: computed('activeType', function() { return this.showInput('user') }),
  showList: computed('activeType', function() { return this.showInput('list') }),
  textEnabled: computed('options.textSelection', 'inputType', function() { return this.optionEnabled('textSelection') }),
  wizardFieldEnabled: computed('options.wizardFieldSelection', 'inputType', function() { return this.optionEnabled('wizardFieldSelection') }),
  wizardActionEnabled: computed('options.wizardActionSelection', 'inputType', function() { return this.optionEnabled('wizardActionSelection') }),
  userFieldEnabled: computed('options.userFieldSelection', 'inputType', function() { return this.optionEnabled('userFieldSelection') }),
  userFieldOptionsEnabled: computed('options.userFieldOptionsSelection', 'inputType', function() { return this.optionEnabled('userFieldOptionsSelection') }),
  categoryEnabled: computed('options.categorySelection', 'inputType', function() { return this.optionEnabled('categorySelection') }),
  tagEnabled: computed('options.tagSelection', 'inputType', function() { return this.optionEnabled('tagSelection') }),
  groupEnabled: computed('options.groupSelection', 'inputType', function() { return this.optionEnabled('groupSelection') }),
  userEnabled: computed('options.userSelection', 'inputType', function() { return this.optionEnabled('userSelection') }),
  listEnabled: computed('options.listSelection', 'inputType', function() { return this.optionEnabled('listSelection') }),
  
  groups: alias('site.groups'),
  categories: alias('site.categories'),
  showComboBox: or('showWizardField', 'showWizardAction', 'showUserField', 'showUserFieldOptions'),
  showMultiSelect: or('showCategory', 'showGroup'),
  hasTypes: gt('selectorTypes.length', 1),
  showTypes: false,
  
  didInsertElement() {
    if (!this.activeType || (this.activeType && !this[`${this.activeType}Enabled`])) {
      later(() => this.resetActiveType());
    }
    
    $(document).on("click", bind(this, this.documentClick));
  },

  willDestroyElement() {
    $(document).off("click", bind(this, this.documentClick));
  },

  documentClick(e) {
    if (this._state == "destroying") return;
    let $target = $(e.target);
        
    if (!$target.parents('.type-selector').length && this.showTypes) {
      this.set('showTypes', false);
    }
  },
  
  @discourseComputed
  selectorTypes() {
    return selectionTypes.filter(type => (this[`${type}Enabled`]))
      .map(type => ({ type, label: this.typeLabel(type) }));
  },
  
  @discourseComputed('activeType')
  activeTypeLabel(activeType) {
    return this.typeLabel(activeType);
  },
  
  typeLabel(type) {
    return type ? I18n.t(`admin.wizard.selector.label.${snakeCase(type)}`) : null;
  },
  
  comboBoxAllowAny: or('showWizardField', 'showWizardAction'),
  
  @discourseComputed
  showController() {
    return getOwner(this).lookup('controller:admin-wizards-wizard-show');
  },
  
  @discourseComputed(
    'activeType',
    'showController.wizardFields.[]',
    'showController.wizard.actions.[]',
    'showController.userFields.[]',
    'showController.currentField.id',
    'showController.currentAction.id'
  )
  comboBoxContent(
    activeType,
    wizardFields,
    wizardActions,
    userFields,
    currentFieldId,
    currentActionId
  ) {
    let content;
    
    if (activeType === 'wizardField') {
      content = wizardFields;
      
      if (this.options.context === 'field') {
        content = content.filter(field => field.id !== currentFieldId);
      }
    }
    
    if (activeType === 'wizardAction') {
      content = wizardActions.map(a => ({
        id: a.id,
        label: `${generateName(a.type)} (${a.id})`,
        type: a.type
      }));
            
      if (this.options.context === 'action') {
        content = content.filter(a => a.id !== currentActionId);
      }
    }
    
    if (activeType === 'userField') {
      content = userProperties.map((f) => ({
        id: f,
        name: generateName(f)
      })).concat((userFields || []));
      
      if (this.options.context === 'action' &&
          this.inputType === 'association' &&
          this.selectorType === 'key') {
        
        const excludedFields = ['username','email', 'trust_level'];
        content = content.filter(userField => excludedFields.indexOf(userField.id) === -1);  
      }
    }
    
    if (activeType === 'userFieldOptions') {
      content = userFields;
    }
    
    return content;
  },
  
  @discourseComputed('activeType')
  multiSelectContent(activeType) {
    return {
      category: this.categories,
      group: this.groups,
      list: ''
    }[activeType];
  },
  
  @discourseComputed('activeType', 'inputType')
  placeholderKey(activeType, inputType) {
    if (activeType === 'text' && this.options[`${this.selectorType}Placeholder`]) {
      return this.options[`${this.selectorType}Placeholder`];
    } else {
      return `admin.wizard.selector.placeholder.${snakeCase(activeType)}`;
    }  
  },
  
  @discourseComputed('activeType')
  multiSelectOptions(activeType) {
    let result = {
      none: this.placeholderKey
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
  
  changeValue(value) {
    this.set('value', value);
    this.onUpdate('selector', this.activeType);
  },
  
  @observes('inputType')
  resetActiveType() {
    this.set('activeType', defaultSelectionType(this.selectorType, this.options));
  },
  
  actions: {
    toggleType(type) {
      this.set('activeType', type);
      this.set('showTypes', false);
      this.set('value', null);
      this.onUpdate('selector');
    },
    
    toggleTypes() {
      this.toggleProperty('showTypes');
    },
    
    changeValue(value) {
      this.changeValue(value);
    },
    
    changeInputValue(event) {
      this.changeValue(event.target.value);
    },
    
    changeUserValue(previousValue, value) {
      this.changeValue(value);
    }
  }
})