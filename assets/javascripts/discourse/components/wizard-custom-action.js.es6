import { default as computed } from 'ember-addons/ember-computed-decorators';

const ACTION_TYPES = [
  { id: 'create_topic', name: 'create_topic *' },
  { id: 'update_profile', name: 'update_profile *' },
  { id: 'send_message', name: 'send_message *' }
];

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
  types: ACTION_TYPES,
  profileFields: PROFILE_FIELDS,
  createTopic: Ember.computed.equal('action.type', 'create_topic'),
  updateProfile: Ember.computed.equal('action.type', 'update_profile'),
  sendMessage: Ember.computed.equal('action.type', 'send_message'),
  disableId: Ember.computed.not('action.isNew'),

  @computed('steps')
  wizardFields(steps) {
    let fields = [];
    steps.forEach((s) => {
      let stepFields = s.fields.map((f) => {
        return Ember.Object.create({
          id: f.id,
          label: `${f.id} (${s.id})`
        });
      });
      fields.push(...stepFields);
    });
    return fields;
  }
});
