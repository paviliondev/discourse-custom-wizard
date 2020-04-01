import {
  default as computed,
  observes
} from 'discourse-common/utils/decorators';
import {
  actionTypes,
  generateName,
  generateSelectKitContent,
  profileFields
} from '../lib/custom-wizard';

export default Ember.Component.extend({
  classNames: 'wizard-custom-action',
  types: actionTypes.map(t => ({ id: t, name: generateName(t) })),
  createTopic: Ember.computed.equal('action.type', 'create_topic'),
  updateProfile: Ember.computed.equal('action.type', 'update_profile'),
  sendMessage: Ember.computed.equal('action.type', 'send_message'),
  sendToApi: Ember.computed.equal('action.type', 'send_to_api'),
  apiEmpty: Ember.computed.empty('action.api'),
  addToGroup: Ember.computed.equal('action.type', 'add_to_group'),
  routeTo: Ember.computed.equal('action.type', 'route_to'),
  disableId: Ember.computed.not('action.isNew'),
  groupPropertyTypes: generateSelectKitContent(['id', 'name']),

  @computed('action.type')
  basicTopicFields(actionType) {
    return ['create_topic', 'send_message', 'open_composer'].indexOf(actionType) > -1;
  },

  @computed('action.type')
  publicTopicFields(actionType) {
    return ['create_topic', 'open_composer'].indexOf(actionType) > -1;
  },

  @computed('action.type')
  newTopicFields(actionType) {
    return ['create_topic', 'send_message'].indexOf(actionType) > -1;
  },
  
  @computed('wizardFields')
  categoryFields(fields) {
    return fields.filter(f => f.type == 'category');
  },
  
  @computed('wizardFields')
  tagFields(fields) {
    return fields.filter(f => f.type == 'tag');
  },

  @observes('action.custom_category_wizard_field')
  toggleCustomCategoryUserField() {
    if (this.action.custom_category_wizard_field) 
      this.set('action.custom_category_user_field', false);
  },

  @observes('action.custom_category_user_field')
  toggleCustomCategoryWizardField() {
    if (this.action.custom_category_user_field)
      this.set('action.custom_category_wizard_field', false);
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
