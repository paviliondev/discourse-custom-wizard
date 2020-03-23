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
      text: I18n.t('admin.wizard.text'),
      wizard: I18n.t('admin.wizard.label'),
      user: I18n.t('users_lowercase.one'),
      category: I18n.t('categories.category'),
      tag: I18n.t('tagging.tags'),
      group: I18n.t('groups.title.one')
    };
    return map[type].toLowerCase();
  },
  
  click() {
    this.toggle(this.type)
  }
})