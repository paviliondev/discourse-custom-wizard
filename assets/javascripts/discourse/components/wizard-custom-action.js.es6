import { on, observes, default as computed } from 'ember-addons/ember-computed-decorators';

const PROFILE_FIELDS = [
  'name',
  'email',
  'username',
  'title',
  'date_of_birth',
  'muted_usernames',
  'theme_key',
  'locale',
  'bio_raw',
  'location',
  'website',
  'dismissed_banner_key',
  'profile_background',
  'card_background'
];

export default Ember.Component.extend({
  classNames: 'wizard-custom-action',
  types: ['create_topic', 'update_profile', 'send_message'],
  profileFields: PROFILE_FIELDS,
  createTopic: Ember.computed.equal('action.type', 'create_topic'),
  updateProfile: Ember.computed.equal('action.type', 'update_profile'),
  sendMessage: Ember.computed.equal('action.type', 'send_message'),

  @on('init')
  @observes('action')
  setup() {
    if (!this.get('isNew')) this.set('existingId', this.get('action.id'));
  },

  @computed('steps')
  wizardFields(steps) {
    let fields = [];
    steps.forEach((s) => {
      let stepFields = s.fields.map((f) => `${f.id} (${s.id})`);
      fields.push(...stepFields);
    });
    return fields;
  },

  @computed('action.profile_updates.[]')
  profileUpdates: fields => fields,

  actions: {
    addProfileUpdate() {
      if (!this.get('action.profile_updates')) {
        this.set('action.profile_updates', Ember.A());
      }
      this.get('action.profile_updates').pushObject(Ember.Object.create());
    },

    removeProfileUpdate(f) {
      this.get('action.profile_updates').removeObject(f);
    }
  }
});
