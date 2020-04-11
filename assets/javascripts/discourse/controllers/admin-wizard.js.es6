import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import { notEmpty, alias } from "@ember/object/computed";
import showModal from 'discourse/lib/show-modal';
import { generateId } from '../lib/wizard';
import { buildProperties } from '../lib/wizard-json';
import { dasherize } from "@ember/string";
import EmberObject from "@ember/object";
import { scheduleOnce, later } from "@ember/runloop";
import Controller from "@ember/controller";
import copyText from "discourse/lib/copy-text";

export default Controller.extend({
  hasName: notEmpty('model.name'),
  userFields: alias('model.userFields'),
  
  @observes('currentStep')
  resetCurrentObjects() {
    const currentStep = this.currentStep;
    
    if (currentStep) {
      const fields = currentStep.fields;
      this.set('currentField', fields && fields.length ? fields[0] : null)
    }
    
    scheduleOnce('afterRender', () => ($("body").addClass('admin-wizard')));
  },
    
  @observes('model.name')
  setId() {
    if (!this.model.existingId) {
      this.set('model.id', generateId(this.model.name));
    }
  },
  
  @discourseComputed('model.id')
  wizardUrl(wizardId) {
    return window.location.origin + '/w/' + dasherize(wizardId);
  },

  @discourseComputed('model.after_time_scheduled')
  nextSessionScheduledLabel(scheduled) {
    return scheduled ?
      moment(scheduled).format('MMMM Do, HH:mm') :
      I18n.t('admin.wizard.after_time_time_label');
  },
  
  @discourseComputed('currentStep.id', 'model.save_submissions', 'model.steps.@each.fields[]')
  wizardFields(currentStepId, saveSubmissions) {
    const allSteps = this.get('model.steps');
    let steps = allSteps;
    let fields = [];

    if (!saveSubmissions) {
      steps = [allSteps.findBy('id', currentStepId)];
    }

    steps.forEach((s) => {
      if (s.fields && s.fields.length > 0) {
        let stepFields = s.fields.map((f) => {
          return EmberObject.create({
            id: f.id,
            label: `${f.label} (${s.id}, ${f.id})`,
            type: f.type
          });
        });
        
        fields.push(...stepFields);
      }
    });

    return fields;
  },

  actions: {
    save() {
      this.setProperties({
        saving: true,
        error: null
      });
      
      const wizard = this.model;
      
      wizard.save().then((result) => {
        
        this.model.setProperties(
          buildProperties(result.wizard)
        );
      
        this.set('saving', false);
        
        if (this.get('newWizard')) {
          this.send("refreshAllWizards");
        } else {
          this.send("refreshWizard");
        }
      }).catch((result) => {
        this.set('saving', false);
                
        let errorType = 'failed';
        let errorParams = {};
        
        if (result.error) {
          errorType = result.error.type;
          errorParams = result.error.params;
        }
        
        this.set('error', I18n.t(`admin.wizard.error.${errorType}`, errorParams));
        
        later(() => this.set('error', null), 10000);
      });
    },

    remove() {
      const wizard = this.get('model');
      wizard.remove().then(() => {
        this.send("refreshAllWizards");
      });
    },

    setNextSessionScheduled() {
      let controller = showModal('next-session-scheduled', {
        model: {
          dateTime: this.get('model.after_time_scheduled'),
          update: (dateTime) => this.set('model.after_time_scheduled', dateTime)
        }
      });

      controller.setup();
    },
    
    toggleAdvanced() {
      this.toggleProperty('model.showAdvanced');
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
