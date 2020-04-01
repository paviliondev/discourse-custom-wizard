import { ajax } from 'discourse/lib/ajax';
import EmberObject from "@ember/object";
import { buildStepJson, buildJson, buildProperties } from '../lib/json';

const CustomWizard = EmberObject.extend({
  save() {
    return new Ember.RSVP.Promise((resolve, reject) => {
      let wizardJson = buildJson(this, 'wizard');
      
      if (wizardJson.after_time && !wizardJson.after_time_scheduled) {
        reject({
          error: 'after_time_need_time'
        });
      };
                  
      if (this.steps.length > 0)  {
        let stepsResult = buildStepJson(this.steps);
                        
        if (stepsResult.error ||
           !stepsResult.steps ||
           stepsResult.steps.length < 1) {
                    
          reject({
            error: stepsResult.error || 'steps_required'
          });
        } else {
          wizardJson.steps = stepsResult.steps;
        }
      }
      
      ajax("/admin/wizards/custom/save", {
        type: 'PUT',
        data: {
          wizard: JSON.stringify(wizardJson)
        }
      }).then((result) => {
        console.log('result: ', result);
        if (result.error) {
          reject(result);
        } else {
          resolve(result);
        }
      });
    });
  },

  remove() {
    return ajax("/admin/wizards/custom/remove", {
      type: 'DELETE',
      data: {
        id: this.get('id')
      }
    }).then(() => this.destroy());
  }
});

CustomWizard.reopenClass({
  all() {
    return ajax("/admin/wizards/custom/all", {
      type: 'GET'
    }).then(result => {
      return result.wizards.map(wizard => {
        return CustomWizard.create(wizard);
      });
    });
  },

  submissions(wizardId) {
    return ajax(`/admin/wizards/submissions/${wizardId}`, {
      type: "GET"
    }).then(result => {
      return result.submissions;
    });
  },

  create(wizardJson = {}) {
    const wizard = this._super.apply(this);
    wizard.setProperties(buildProperties(wizardJson));
    return wizard;
  }
});

export default CustomWizard;
