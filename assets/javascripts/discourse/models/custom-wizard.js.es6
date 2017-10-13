import { ajax } from 'discourse/lib/ajax';

const CustomWizard = Discourse.Model.extend({
  save() {
    return new Ember.RSVP.Promise((resolve, reject) => {
      const id = this.get('id');
      if (!id || !id.underscore()) reject('id_required');

      let wizard = { id: id.underscore() };

      const steps = this.get('steps');
      if (steps.length) wizard['steps'] = this.buildSteps(steps, reject);

      const name = this.get('name');
      if (name) wizard['name'] = name;

      const background = this.get('background');
      if (background) wizard['background'] = background;

      const save_submissions = this.get('save_submissions');
      if (save_submissions) wizard['save_submissions'] = save_submissions;

      const multiple_submissions = this.get('multiple_submissions');
      if (multiple_submissions) wizard['multiple_submissions'] = multiple_submissions;

      ajax("/admin/wizards/custom/save", {
        type: 'PUT',
        data: {
          wizard: JSON.stringify(wizard)
        }
      }).then((result) => resolve(result));
    });
  },

  buildSteps(stepsObj, reject) {
    let steps = [];

    stepsObj.some((s) => {
      if (!s.id || !s.id.underscore()) reject('id_required');

      let step = { id: s.id.underscore() };

      if (s.title) step['title'] = s.title;
      if (s.key) step['key'] = s.key;
      if (s.banner) step['banner'] = s.banner;
      if (s.description) step['description'] = s.description;

      const fields = s.get('fields');
      if (fields.length) {
        step['fields'] = [];

        fields.some((f) => {
          let id = f.get('id');

          if (!id || !id.underscore()) reject('id_required');
          f.set('id', id.underscore());

          if (f.get('type') === 'dropdown') {
            const choices = f.get('choices');
            if (choices && choices.length < 1 && !f.get('choices_key') && !f.get('choices_categories')) {
              reject('field.need_choices');
            }
          }

          step['fields'].push(f);
        });
      }

      const actions = s.actions;
      if (actions.length) {
        step['actions'] = [];

        actions.some((a) => {
          let id = a.get('id');
          if (!id || !id.underscore()) reject('id_required');

          a.set('id', id.underscore());

          step['actions'].push(a);
        });

      }

      steps.push(step);
    });

    return steps;
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
      props['existingId'] = true;
      props['name'] = w.name;
      props['background'] = w.background;
      props['save_submissions'] = w.save_submissions;
      props['multiple_submissions'] = w.multiple_submissions;

      if (w.steps && w.steps.length) {
        w.steps.forEach((s) => {
          // clean empty strings
          Object.keys(s).forEach((key) => (s[key] === '') && delete s[key]);

          let fields =  Ember.A();

          if (s.fields && s.fields.length) {
            s.fields.forEach((f) => {
              Object.keys(f).forEach((key) => (f[key] === '') && delete f[key]);

              let field = Ember.Object.create(f);

              if (f.choices) {
                let choices = Ember.A();

                f.choices.forEach((c) => {
                  choices.pushObject(Ember.Object.create(c));
                });

                field.set('choices', choices);
              }

              fields.pushObject(field);
            });
          }

          let actions = Ember.A();
          if (s.actions && s.actions.length) {
            s.actions.forEach((a) => {
              actions.pushObject(Ember.Object.create(a));
            });
          }

          steps.pushObject(Ember.Object.create({
            id: s.id,
            key: s.key,
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
      props['multiple_submissions'] = false;
      props['steps'] = Ember.A();
    };

    wizard.setProperties(props);

    return wizard;
  }
});

export default CustomWizard;
