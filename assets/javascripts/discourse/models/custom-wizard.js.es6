import { ajax } from 'discourse/lib/ajax';
import { default as computed } from 'ember-addons/ember-computed-decorators';

const CustomWizard = Discourse.Model.extend({
  steps: Ember.A(),

  @computed('name')
  dasherizedName(name) {
    return Ember.String.dasherize(name);
  },

  save() {
    const wizard = {
      id: this.get('id'),
      steps: this.get('steps').toArray(),
      name: this.get('name')
    };

    return ajax(`/admin/wizards/custom/save`, {
      type: 'PUT',
      data: {
        wizard: JSON.stringify(wizard)
      }
    });
  },

  remove() {
    return ajax(`/admin/wizards/custom/remove`, {
      type: 'DELETE',
      data: {
        id: this.get('id')
      }
    }).then(() => this.destroy());
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
      s.fields.forEach((f) => f.choices = Ember.A(f.choices));
      s.actions = Ember.A(s.actions);
    });

    return wizard;
  }
});

export default CustomWizard;
