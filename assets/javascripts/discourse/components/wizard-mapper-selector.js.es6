import { alias, or, gt } from "@ember/object/computed";
import { computed } from "@ember/object";
import { default as discourseComputed, observes, on } from "discourse-common/utils/decorators";
import { getOwner } from 'discourse-common/lib/get-owner';
import { defaultSelectionType, selectionTypes, removeMapperClasses } from '../lib/wizard-mapper'; 
import { snakeCase } from '../lib/wizard';
import Component from "@ember/component";
import { bind } from "@ember/runloop";

export default Component.extend({
  classNameBindings: [':mapper-selector', 'activeType'],
  groups: alias('site.groups'),
  categories: alias('site.categories'),
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
  hasTypes: gt('selectorTypes.length', 1),
  
  didInsertElement() {
    $(document).on("click", bind(this, this.documentClick));
  },

  willDestroyElement() {
    $(document).off("click", bind(this, this.documentClick));
  },

  documentClick(e) {
    if (this._state == "destroying") return;
    
    let $target = $(e.target);
    
    if (!$target.parents('.wizard-mapper .input').length) {
      this.send('disableActive');
    }
    
    if (!$target.parents('.type-selector').length) {
      this.send('hideTypes');
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
    return I18n.t(`admin.wizard.selector.label.${snakeCase(type)}`)
  },
  
  @observes('inputType')
  resetActiveType() {
    this.set('activeType', defaultSelectionType(this.selectorType, this.options));
  },
  
  @observes('activeType')
  clearValue() {
    this.set('value', null);
  },
  
  @discourseComputed('activeType')
  comboBoxContent(activeType) {
    const controller = getOwner(this).lookup('controller:admin-wizard');
    let content = controller[`${activeType}s`];
    
    // you can't select the current field in the field context
    if (activeType === 'wizardField' && this.options.context === 'field') {
      content = content.filter(field => field.id !== controller.currentField.id);
    }
    
    // updating usernames or emails via actions is not supported
    if (activeType === 'userField' &&
        this.options.context === 'action' &&
        this.inputType === 'association' &&
        this.selectorType === 'key') {
      
      content = content.filter(userField => ['username','email'].indexOf(userField.id) === -1);  
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
  
  removeClasses() {
    removeMapperClasses(this);
  },
  
  actions: {
    toggleType(type) {
      this.set('activeType', type);
      this.send('hideTypes');
    },
    
    // jquery is used here to ensure other selectors and types disable properly
    
    showTypes() {
      this.removeClasses();
      $(this.element).find('.selector-types').addClass('show');
    },
    
    hideTypes() {
      $(this.element).find('.selector-types').removeClass('show');
    },
  
    enableActive() {
      this.removeClasses();
      $(this.element).addClass('active');
    },
    
    disableActive() {
      $(this.element).removeClass('active');
    }
  }
})