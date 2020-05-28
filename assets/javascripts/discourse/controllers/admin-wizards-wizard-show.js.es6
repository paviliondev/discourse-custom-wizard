import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import { notEmpty, alias } from "@ember/object/computed";
import showModal from 'discourse/lib/show-modal';
import { generateId, wizardFieldList } from '../lib/wizard';
import { buildProperties } from '../lib/wizard-json';
import { dasherize } from "@ember/string";
import EmberObject from "@ember/object";
import { scheduleOnce, later } from "@ember/runloop";
import Controller from "@ember/controller";
import copyText from "discourse/lib/copy-text";
import CustomWizard from '../models/custom-wizard';
import I18n from "I18n";

export default Controller.extend({
  hasName: notEmpty('wizard.name'),
  
  @observes('currentStep')
  resetCurrentObjects() {
    const currentStep = this.currentStep;
    
    if (currentStep) {
      const fields = currentStep.fields;
      this.set('currentField', fields && fields.length ? fields[0] : null)
    }
    
    scheduleOnce('afterRender', () => ($("body").addClass('admin-wizard')));
  },
    
  @observes('wizard.name')
  setId() {
    const wizard = this.wizard;    
    if (wizard && !wizard.existingId) {      
      this.set('wizard.id', generateId(wizard.name));
    }
  },
  
  @discourseComputed('wizard.id')
  wizardUrl(wizardId) {
    return window.location.origin + '/w/' + dasherize(wizardId);
  },

  @discourseComputed('wizard.after_time_scheduled')
  nextSessionScheduledLabel(scheduled) {
    return scheduled ?
      moment(scheduled).format('MMMM Do, HH:mm') :
      I18n.t('admin.wizard.after_time_time_label');
  },
  
  @discourseComputed('currentStep.id', 'wizard.save_submissions', 'wizard.steps.@each.fields[]')
  wizardFields(currentStepId, saveSubmissions) {
    let steps = this.wizard.steps;
    if (!saveSubmissions) {
      steps = [steps.findBy('id', currentStepId)];
    }
    return wizardFieldList(steps);
  },

  actions: {    
    save() {
      this.setProperties({
        saving: true,
        error: null
      });
      
      const wizard = this.wizard;
      const creating = this.creating;
      let opts = {};
      
      if (creating) {
        opts.create = true;
      }
      
      wizard.save(opts).then((result) => {
        this.send('afterSave', result.wizard_id);
      }).catch((result) => {                
        let errorType = 'failed';
        let errorParams = {};
        
        if (result.error) {
          errorType = result.error.type;
          errorParams = result.error.params;
        }
        
        this.set('error', I18n.t(`admin.wizard.error.${errorType}`, errorParams));
        
        later(() => this.set('error', null), 10000);
      }).finally(() => this.set('saving', false));
    },

    remove() {
      this.wizard.remove().then(() => this.send('afterDestroy'));
    },

    setNextSessionScheduled() {
      let controller = showModal('next-session-scheduled', {
        model: {
          dateTime: this.wizard.after_time_scheduled,
          update: (dateTime) => this.set('wizard.after_time_scheduled', dateTime)
        }
      });

      controller.setup();
    },
    
    toggleAdvanced() {
      this.toggleProperty('wizard.showAdvanced');
    },
    
    copyUrl() {
      const $copyRange = $('<p id="copy-range"></p>');
      $copyRange.html(this.wizardUrl);
      
      $(document.body).append($copyRange);
      
      if (copyText(this.wizardUrl, $copyRange[0])) {
        this.set("copiedUrl", true);
        later(() => this.set("copiedUrl", false), 2000);
      }
      
      $copyRange.remove();
    }
  }
});
