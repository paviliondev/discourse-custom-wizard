import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  targets: ['topic', 'profile', 'email', 'badge', 'save'],
  isTopic: Ember.computed.equal('targets', 'topic'),

  init() {
    this._super(...arguments);
    console.log(this)
  },
});
