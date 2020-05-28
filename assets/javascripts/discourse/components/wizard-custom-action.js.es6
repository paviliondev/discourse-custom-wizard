import { default as discourseComputed } from 'discourse-common/utils/decorators';
import { equal, empty, or, and } from "@ember/object/computed";
import { generateName, selectKitContent } from '../lib/wizard';
import { computed } from "@ember/object";
import wizardSchema from '../lib/wizard-schema';
import UndoChanges from '../mixins/undo-changes';
import Component from "@ember/component";
import { notificationLevels } from '../lib/wizard';
import I18n from "I18n";

export default Component.extend(UndoChanges, {
  componentType: 'action',
  classNameBindings: [':wizard-custom-action', 'visible'],
  visible: computed('currentActionId', function() { return this.action.id === this.currentActionId }),
  createTopic: equal('action.type', 'create_topic'),
  updateProfile: equal('action.type', 'update_profile'),
  watchCategories: equal('action.type', 'watch_categories'),
  sendMessage: equal('action.type', 'send_message'),
  openComposer: equal('action.type', 'open_composer'),
  sendToApi: equal('action.type', 'send_to_api'),
  addToGroup: equal('action.type', 'add_to_group'),
  routeTo: equal('action.type', 'route_to'),
  apiEmpty: empty('action.api'),
  groupPropertyTypes: selectKitContent(['id', 'name']),
  hasAdvanced: or('hasCustomFields', 'routeTo'),
  showAdvanced: and('hasAdvanced', 'action.type'),
  hasCustomFields: or('basicTopicFields', 'updateProfile'),
  basicTopicFields: or('createTopic', 'sendMessage', 'openComposer'),
  publicTopicFields: or('createTopic', 'openComposer'),
  showSkipRedirect: or('createTopic', 'sendMessage'),
  actionTypes: Object.keys(wizardSchema.action.types).map(type => {
    return {
      id: type,
      name: I18n.t(`admin.wizard.action.${type}.label`)
    };
  }),
  availableNotificationLevels: notificationLevels.map((type, index) => {
    return {
      id: type,
      name:  I18n.t(`admin.wizard.action.watch_categories.notification_level.${type}`)
    };
  }),
  
  messageUrl: 'https://thepavilion.io/t/2810',
  
  @discourseComputed('action.type')
  messageKey(type) {
    let key = 'type';
    if (type) {
      key = 'edit';
    }
    return key;
  },
  
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

  @discourseComputed('apis')
  availableApis(apis) {
    return apis.map(a => {
      return {
        id: a.name,
        name: a.title
      };
    });
  },

  @discourseComputed('apis', 'action.api')
  availableEndpoints(apis, api) {
    if (!api) return [];
    return apis.find(a => a.name === api).endpoints;
  }
});
