import { default as computed } from 'ember-addons/ember-computed-decorators';
import getUrl from 'discourse-common/lib/get-url';
import WizardField from 'wizard/models/wizard-field';
import { ajax } from 'wizard/lib/ajax';
import Step from 'wizard/models/step';

const CustomWizard = Ember.Object.extend({
  @computed('steps.length')
  totalSteps: length => length,

  skip() {
    if (this.get('required') && (!this.get('completed') && this.get('permitted'))) return;
    const id = this.get('id');
    CustomWizard.skip(id);
  }
});

CustomWizard.reopenClass({
  skip(wizardId) {
    ajax({ url: `/w/${wizardId}/skip`, type: 'PUT' }).then((result) => {
      CustomWizard.finished(result);
    });
  },

  finished(result) {
    let url = "/";
    if (result.redirect_to) {
      url = result.redirect_to;
    }
    window.location.href = getUrl(url);
  }
});

export function findCustomWizard(wizardId, opts = {}) {
  let url = `/w/${wizardId}`;
  if (opts.reset) url += '?reset=true';

  return ajax({ url, cache: false, dataType: 'json' }).then(result => {
    const wizard = result.wizard;

    if (!wizard) return null;

    if (!wizard.completed) {
      wizard.steps = wizard.steps.map(step => {
        const stepObj = Step.create(step);
        stepObj.fields = stepObj.fields.map(f => WizardField.create(f));
        return stepObj;
      });
    }

    return CustomWizard.create(wizard);
  });
};

export default CustomWizard;
