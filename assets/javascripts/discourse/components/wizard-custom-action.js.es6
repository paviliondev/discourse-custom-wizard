export default Ember.Component.extend({
  targets: ['topic', 'profile', 'email', 'badge', 'save'],
  isTopic: Ember.computed.equal('targets', 'topic')
});
