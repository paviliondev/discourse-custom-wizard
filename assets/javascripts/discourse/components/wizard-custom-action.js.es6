import { on, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-action',
  types: ['create_topic', 'update_profile', 'send_message'],
  profileFields: ['name', 'username', 'email'],
  createTopic: Ember.computed.equal('action.type', 'create_topic'),
  updateProfile: Ember.computed.equal('action.type', 'update_profile'),
  sendMessage: Ember.computed.equal('action.type', 'send_message'),

  @on('init')
  @observes('action')
  setup() {
    this.set('existingId', this.get('action.id'));
  }
});
