import { default as computed } from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';

const CustomWizard = Discourse.Model.extend({
  init() {
    const id = this.get('id');
    if (id) this.set('existingId', id);
  },

  @computed('name')
  id(name) {
    return name ? Ember.String.dasherize(name) : null;
  },

  save() {
    const stepsObj = this.get('steps');
    let steps = [];

    stepsObj.forEach((s) => {
      let step = {
        id: Ember.String.dasherize(s.title),
        title: s.title,
        banner: s.banner,
        description: s.description,
        fields: [],
        actions: []
      };

      const fields = s.get('fields');
      fields.forEach((f) => {
        f.set('id', Ember.String.dasherize(f.get('label')));
        step['fields'].push(f);
      });

      s.actions.forEach((a) => {
        a['id'] = Ember.String.dasherize(a.label);
        step['actions'].push(a);
      });

      steps.push(step);
    });

    const id = this.get('id');
    const name = this.get('name');
    let wizard = { id, name, steps };

    const existingId = this.get('existingId');
    if (existingId && existingId !== id) {
      wizard['existing_id'] = existingId;
    };

    return ajax("/admin/wizards/custom/save", {
      type: 'PUT',
      data: {
        wizard: JSON.stringify(wizard)
      }
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
  findAll() {
    return ajax("/admin/wizards/custom/all", {
      type: 'GET'
    }).then(result => {
      return result.wizards.map(w => CustomWizard.create(w));
    });
  },

  create(w) {
    const wizard = this._super.apply(this);

    let steps = Ember.A();
    let props = { steps };

    if (w) {
      props['id'] = w.id; props['name'] = w.name;

      if (w.steps) {
        w.steps.forEach((s) => {
          let fields = Ember.A();

          s.fields.forEach((f) => {
            let choices = Ember.A();

            f.choices.forEach((c) => {
              choices.pushObject(Ember.Object.create(c));
            });

            fields.pushObject(Ember.Object.create(f));
          });

          let actions = Ember.A();
          s.actions.forEach((a) => {
            actions.pushObject(Ember.Object.create(a));
          });

          steps.pushObject(Ember.Object.create({
            id: s.id,
            title: s.title,
            description: s.description,
            fields,
            actions
          }));
        });
      }
    };

    wizard.setProperties(props);

    return wizard;
  }
});

export default CustomWizard;
