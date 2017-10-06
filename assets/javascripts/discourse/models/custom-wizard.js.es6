import { default as computed } from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';

const CustomWizard = Discourse.Model.extend({
  init() {
    const id = this.get('id');
    if (id) this.set('existingId', id);
  },

  @computed('name')
  id: (name) => name ? Ember.String.dasherize(name) : null,

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

        if (f.get('type') === 'dropdown') {
          const choices = f.get('choices');
          choices.forEach((c) => {
            c.set('id', c.get('label'));
          });
        }

        step['fields'].push(f);
      });

      s.actions.forEach((a) => {
        a.set('id', Ember.String.dasherize(a.get('label')));
        step['actions'].push(a);
      });

      steps.push(step);
    });

    const id = this.get('id');
    const name = this.get('name');
    const save_submissions = this.get('save_submissions');
    let wizard = { id, name, save_submissions, steps };

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

  findAllSubmissions() {
    return ajax("/admin/wizards/submissions/all", {
      type: "GET"
    }).then(result => {
      return result.submissions;
    });
  },

  create(w) {
    const wizard = this._super.apply(this);

    let steps = Ember.A();
    let props = { steps };

    if (w) {
      props['id'] = w.id;
      props['name'] = w.name;

      if (w.steps) {
        w.steps.forEach((s) => {
          let fields = Ember.A();

          s.fields.forEach((f) => {
            let field = Ember.Object.create(f);
            let choices = Ember.A();

            f.choices.forEach((c) => {
              choices.pushObject(Ember.Object.create(c));
            });

            field.set('choices', choices);

            fields.pushObject(field);
          });

          let actions = Ember.A();
          s.actions.forEach((a) => {
            actions.pushObject(Ember.Object.create(a));
          });

          steps.pushObject(Ember.Object.create({
            id: s.id,
            title: s.title,
            description: s.description,
            banner: s.banner,
            fields,
            actions
          }));
        });
      };
    } else {
      props['save_submissions'] = true;
    };

    wizard.setProperties(props);

    return wizard;
  }
});

export default CustomWizard;
