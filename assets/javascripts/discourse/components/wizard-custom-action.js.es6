import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import { equal, empty, or } from "@ember/object/computed";
import { generateName, selectKitContent } from '../lib/wizard';
import wizardSchema from '../lib/wizard-schema';
import Component from "@ember/component";

export default Component.extend({
  classNames: 'wizard-custom-action',
  actionTypes: Object.keys(wizardSchema.action.types).map(t => ({ id: t, name: generateName(t) })),
  createTopic: equal('action.type', 'create_topic'),
  updateProfile: equal('action.type', 'update_profile'),
  sendMessage: equal('action.type', 'send_message'),
  openComposer: equal('action.type', 'open_composer'),
  sendToApi: equal('action.type', 'send_to_api'),
  addToGroup: equal('action.type', 'add_to_group'),
  routeTo: equal('action.type', 'route_to'),
  apiEmpty: empty('action.api'),
  groupPropertyTypes: selectKitContent(['id', 'name']),
  hasAdvanced: or('hasCustomFields', 'routeTo'),
  hasCustomFields: or('basicTopicFields', 'updateProfile'),
  basicTopicFields: or('createTopic', 'sendMessage', 'openComposer'),
  publicTopicFields: or('createTopic', 'openComposer'),
  showSkipRedirect: or('createTopic', 'sendMessage'),
  
  @discourseComputed('wizard.steps')
  runAfterContent(steps) {
    let content = steps.map(function(step) {
      return {
        id: step.id,
        name: step.title || step.id
      };
    });
    
    content.unshift({
      id: 'wizard_completion',
      name: I18n.t('admin.wizard.action.run_after.wizard_completion')
    });
        
    return content;
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
