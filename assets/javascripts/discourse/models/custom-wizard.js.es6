import { ajax } from 'discourse/lib/ajax';

const CustomWizard = Discourse.Model.extend({
  steps: Ember.A(),

  save() {
    const steps = JSON.stringify(this.get('steps').toArray());
    return ajax(`/admin/wizards/custom/${this.get('name')}`, {
      type: 'PUT',
      data: { steps }
    });
  },

  destroy() {
    return ajax(`/admin/wizards/custom/${this.get('name')}`, {
      type: 'DELETE'
    });
  }
});

CustomWizard.reopenClass({
  findAll() {
    return ajax("/admin/wizards/custom/all").then(result => {
      return result.wizards.map(w => CustomWizard.create(w));
    });
  },

  create() {
    const wizard = this._super.apply(this, arguments);
    const steps = wizard.get('steps');

    steps.forEach((s) => {
      s.fields = Ember.A(s.fields);
      s.actions = Ember.A(s.actions);
    });

    return wizard;
  }
});

export default CustomWizard;
