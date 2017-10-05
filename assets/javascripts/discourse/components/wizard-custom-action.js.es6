export default Ember.Component.extend({
  types: ['create_topic', 'update_profile', 'send_message'],
  profileFields: ['name', 'username', 'email'],
  createTopic: Ember.computed.equal('action.type', 'create_topic'),
  updateProfile: Ember.computed.equal('action.type', 'update_profile'),
  sendMessage: Ember.computed.equal('action.type', 'send_message'),

  test: function() {
    console.log(this.get('stepFields'));
  }.observes('stepFields.[]')
});
