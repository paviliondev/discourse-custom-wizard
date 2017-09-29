import { default as computed } from 'ember-addons/ember-computed-decorators';
import WizardField from 'wizard/models/wizard-field';
import { ajax } from 'wizard/lib/ajax';
import Step from 'wizard/models/step';

const CustomWizard = Ember.Object.extend({
  @computed('steps.length')
  totalSteps: length => length
});

export function findCustomWizard(wizardId) {
  return ajax({ url: `/wizard/custom/${wizardId}` }).then(result => {
    const wizard = result.wizard;
    wizard.steps = wizard.steps.map(step => {
      const stepObj = Step.create(step);
      stepObj.fields = stepObj.fields.map(f => WizardField.create(f));
      return stepObj;
    });

    console.log(wizard)

    return CustomWizard.create(wizard);
  });
};

export default CustomWizard;
