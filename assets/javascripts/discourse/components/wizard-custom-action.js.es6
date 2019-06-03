import { default as computed, observes } from 'ember-addons/ember-computed-decorators';

const ACTION_TYPES = [
  { id: 'create_topic', name: 'Create Topic' },
  { id: 'update_profile', name: 'Update Profile' },
  { id: 'send_message', name: 'Send Message' },
  { id: 'send_to_api', name: 'Send to API' }
];

const PROFILE_FIELDS = [
  'name',
  'date_of_birth',
  'title',
  'locale',
  'location',
  'website',
  'bio_raw',
  'profile_background',
  'card_background',
  'theme_id'
];

export default Ember.Component.extend({
  classNames: 'wizard-custom-action',
  types: ACTION_TYPES,
  profileFields: PROFILE_FIELDS,
  createTopic: Ember.computed.equal('action.type', 'create_topic'),
  updateProfile: Ember.computed.equal('action.type', 'update_profile'),
  sendMessage: Ember.computed.equal('action.type', 'send_message'),
  sendToApi: Ember.computed.equal('action.type', 'send_to_api'),
  apiEmpty: Ember.computed.empty('action.api'),
  disableId: Ember.computed.not('action.isNew'),

  @computed('currentStepId', 'wizard.save_submissions')
  availableFields(currentStepId, saveSubmissions) {
    const allSteps = this.get('wizard.steps');
    let steps = allSteps;
    let fields = [];

    if (!saveSubmissions) {
      steps = [allSteps.findBy('id', currentStepId)];
    }

    steps.forEach((s) => {
      if (s.fields && s.fields.length > 0) {
        let stepFields = s.fields.map((f) => {
          return Ember.Object.create({
            id: f.id,
            label: `${f.id} (${s.id})`
          });
        });
        fields.push(...stepFields);
      }
    });

    return fields;
  },

  @computed('availableFields')
  builderWizardFields(fields) {
    return fields.map((f) => ` w{${f.id}}`);
  },

  @computed()
  builderUserFields() {
    const noTheme = PROFILE_FIELDS.filter((f) => f !== 'theme_id');
    const fields = noTheme.concat(['email', 'username']);
    return fields.map((f) => ` u{${f}}`);
  },

  @observes('action.custom_category_wizard_field')
  toggleCustomCategoryUserField() {
    const wizard = this.get('action.custom_category_wizard_field');
    if (wizard) this.set('action.custom_category_user_field', false);
  },

  @observes('action.custom_category_user_field')
  toggleCustomCategoryWizardField() {
    const user = this.get('action.custom_category_user_field');
    if (user) this.set('action.custom_category_wizard_field', false);
  },

  @computed('wizard.apis')
  availableApis(apis) {
    return apis.map(a => {
      return {
        id: a.name,
        name: a.title
      };
    });
  },

  @computed('wizard.apis', 'action.api')
  availableEndpoints(apis, api) {
    if (!api) return [];
    return apis.find(a => a.name === api).endpoints;
  }
});
