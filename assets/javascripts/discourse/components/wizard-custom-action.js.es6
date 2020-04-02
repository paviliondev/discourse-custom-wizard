import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import { equal, not, empty, or } from "@ember/object/computed";
import {
  actionTypes,
  generateName,
  selectKitContent,
  profileFields
} from '../lib/wizard';

export default Ember.Component.extend({
  classNames: 'wizard-custom-action',
  types: actionTypes.map(t => ({ id: t, name: generateName(t) })),
  createTopic: equal('action.type', 'create_topic'),
  updateProfile: equal('action.type', 'update_profile'),
  sendMessage: equal('action.type', 'send_message'),
  sendToApi: equal('action.type', 'send_to_api'),
  apiEmpty: empty('action.api'),
  addToGroup: equal('action.type', 'add_to_group'),
  routeTo: equal('action.type', 'route_to'),
  disableId: not('action.isNew'),
  groupPropertyTypes: selectKitContent(['id', 'name']),
  hasAdvanced: or('basicTopicFields', 'routeTo'),
  
  @on('didInsertElement')
  @observes('action.type')
  updateId() {
    if (this.action.type) this.set('action.id', generateName(this.action.type));
  },

  @discourseComputed('action.type')
  basicTopicFields(actionType) {
    return ['create_topic', 'send_message', 'open_composer'].indexOf(actionType) > -1;
  },

  @discourseComputed('action.type')
  publicTopicFields(actionType) {
    return ['create_topic', 'open_composer'].indexOf(actionType) > -1;
  },

  @discourseComputed('action.type')
  newTopicFields(actionType) {
    return ['create_topic', 'send_message'].indexOf(actionType) > -1;
  },
  
  @discourseComputed('wizardFields')
  categoryFields(fields) {
    return fields.filter(f => f.type == 'category');
  },
  
  @discourseComputed('wizardFields')
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

  @discourseComputed('wizard.apis')
  availableApis(apis) {
    return apis.map(a => {
      return {
        id: a.name,
        name: a.title
      };
    });
  },

  @discourseComputed('wizard.apis', 'action.api')
  availableEndpoints(apis, api) {
    if (!api) return [];
    return apis.find(a => a.name === api).endpoints;
  }
});
