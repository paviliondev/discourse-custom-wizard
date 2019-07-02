import { default as computed, on } from 'ember-addons/ember-computed-decorators';
import { getOwner } from 'discourse-common/lib/get-owner';

export default Ember.Component.extend({
  classNames: 'custom-input',
  noneKey: 'admin.wizard.select_field',
  noneValue: 'admin.wizard.none',
  connectorNone: 'admin.wizard.none',
  inputKey: 'admin.wizard.key',
  customDisabled: Ember.computed.alias('input.user_field'),

  @computed('input.value_custom', 'input.user_field')
  valueDisabled(custom, user) {
    return Boolean(custom || user);
  },

  @on('init')
  setupUserFields() {
    const allowUserField = this.get('allowUserField');
    if (allowUserField) {
      const store = getOwner(this).lookup('store:main');
      store.findAll('user-field').then((result) => {
        if (result && result.content && result.content.length) {
          this.set('userFields', result.content.map((f) => {
            return {
              id: `user_field_${f.id}`,
              name: f.name
            };
          }));
        }
      });
    }
  }
});
