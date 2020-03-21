import discourseComputed from 'discourse-common/utils/decorators';

export default Ember.Component.extend({
  tagName: 'a',
  classNameBindings: ['type', 'active'],
  
  @discourseComputed('type', 'activeType')
  active(type, activeType) {
    return type === activeType;
  },
  
  @discourseComputed('type')
  label(type) {
    let map = {
      wizard: I18n.t('admin.wizard.label'),
      user: I18n.t('users_lowercase.one'),
      text: I18n.t('admin.wizard.text')
    };
    return map[type].toLowerCase();
  },
  
  click() {
    this.toggle(this.type)
  }
})