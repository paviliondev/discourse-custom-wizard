import { default as discourseComputed } from 'discourse-common/utils/decorators';
import Component from '@ember/component';

export default Component.extend({
  classNames: 'wizard-advanced-toggle',
  
  @discourseComputed('showAdvanced')
  toggleClass(showAdvanced) {
    let classes = 'btn'
    if (showAdvanced) classes += ' btn-primary';
    return classes;
  },
  
  actions: {
    toggleAdvanced() {
      this.toggleProperty('showAdvanced');
    }
  }
})