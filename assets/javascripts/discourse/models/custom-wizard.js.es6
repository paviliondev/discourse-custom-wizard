import { observes, on } from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';

const CustomWizard = Discourse.Model.extend({
  @on('init')
  setup() {
    const id = this.get('id');
    if (id) this.set('existingId', id);
  },

  @observes('name')
  updateId() {
    const name = this.get('name');
    this.set('id', name.underscore());
  },

  save() {
    const stepsObj = this.get('steps');
    let steps = [];

    stepsObj.forEach((s) => {

      if (!s.title && !s.translation_key) return;

      let step = {
        id: (s.title || s.translation_key.split('.').pop()).underscore(),
        fields: [],
        actions: []
      };

      if (s.title) step['title'] = s.title;
      if (s.translation_key) step['translation_key'] = s.translation_key;
      if (s.banner) step['banner'] = s.banner;
      if (s.description) step['description'] = s.description;

      const fields = s.get('fields');
      fields.forEach((f) => {
        const fl = f.get('label');
        const fkey = f.get('translation_key');

        if (!fl && !fkey) return;

        f.set('id', (fl || fkey.split('.').pop()).underscore());

        if (f.get('type') === 'dropdown') {
          const choices = f.get('choices');

          choices.forEach((c) => {
            const cl = c.get('label');
            const ckey = c.get('translation_key');

            if (!cl && !ckey) return;

            c.set('id', (cl || ckey.split('.').pop()).underscore());
          });
        }

        step['fields'].push(f);
      });

      s.actions.forEach((a) => {
        const al = a.get('label');
        if (!al) return;
        a.set('id', al.underscore());
        step['actions'].push(a);
      });

      steps.push(step);
    });

    const id = this.get('id');
    const name = this.get('name');
    const background = this.get('background');
    const save_submissions = this.get('save_submissions');
    let wizard = { id, name, background, save_submissions, steps };

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
      props['background'] = w.background;
      props['save_submissions'] = w.save_submissions;

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
            translation_key: s.translation_key,
            title: s.title,
            description: s.description,
            banner: s.banner,
            fields,
            actions
          }));
        });
      };
    } else {
      props['id'] = '';
      props['name'] = '';
      props['background'] = '';
      props['save_submissions'] = true;
      props['steps'] = Ember.A();
    };

    wizard.setProperties(props);

    return wizard;
  }
});

export default CustomWizard;
