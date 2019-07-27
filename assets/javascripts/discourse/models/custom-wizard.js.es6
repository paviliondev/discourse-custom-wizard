import { ajax } from 'discourse/lib/ajax';

const wizardProperties = [
  'name',
  'background',
  'save_submissions',
  'multiple_submissions',
  'after_signup',
  'after_time',
  'after_time_scheduled',
  'required',
  'prompt_completion',
  'min_trust',
  'theme_id'
];

const CustomWizard = Discourse.Model.extend({
  save() {
    return new Ember.RSVP.Promise((resolve, reject) => {

      const id = this.get('id');
      if (!id || !id.underscore()) return reject({ error: 'id_required' });

      let wizard = { id: id.underscore() };

      wizardProperties.forEach((p) => {
        const value = this.get(p);
        if (value) wizard[p] = value;
      });

      if (wizard['after_time'] && !wizard['after_time_scheduled']) {
        return reject({ error: 'after_time_need_time' });
      };

      const steps = this.get('steps');
      if (steps.length > 0)  {
        const stepsResult = this.buildSteps(steps);
        if (stepsResult.error) {
          reject({ error: stepsResult.error });
        } else {
          wizard['steps'] = stepsResult.steps;
        }
      }

      if (steps.length < 1 || !wizard['steps'] || wizard['steps'].length < 1) {
        return reject({ error: 'steps_required' });
      }

      ajax("/admin/wizards/custom/save", {
        type: 'PUT',
        data: {
          wizard: JSON.stringify(wizard)
        }
      }).then((result) => {
        if (result.error) {
          reject(result);
        } else {
          resolve(result);
        }
      });
    });
  },

  buildSteps(stepsObj) {
    let steps = [];
    let error = null;

    stepsObj.some((s) => {
      if (!s.id || !s.id.underscore()) {
        error = 'id_required';
        return;
      };

      let step = { id: s.id.underscore() };

      if (s.title) step['title'] = s.title;
      if (s.key) step['key'] = s.key;
      if (s.banner) step['banner'] = s.banner;
      if (s.raw_description) step['raw_description'] = s.raw_description;
      if (s.required_data) step['required_data'] = s.required_data;
      if (s.required_data_message) step['required_data_message'] = s.required_data_message;
      if (s.permitted_params) step['permitted_params'] = s.permitted_params;

      const fields = s.get('fields');
      if (fields.length) {
        step['fields'] = [];

        fields.some((f) => {
          let id = f.id;

          if (!id || !id.underscore()) {
            error = 'id_required';
            return;
          }

          if (!f.type) {
            error = 'type_required';
            return;
          }

          f.set('id', id.underscore());

          if (f.label === '') delete f.label;
          if (f.description === '') delete f.description;

          if (f.type === 'dropdown') {
            const choices = f.choices;
            if ((!choices || choices.length < 1) && !f.choices_key && !f.choices_preset) {
              error = 'field.need_choices';
              return;
            }

            if (f.dropdown_none === '') delete f.dropdown_none;
          }

          delete f.isNew;

          step['fields'].push(f);
        });

        if (error) return;
      }

      const actions = s.actions;
      if (actions.length) {
        step['actions'] = [];

        actions.some((a) => {
          let id = a.get('id');
          if (!id || !id.underscore()) {
            error = 'id_required';
            return;
          }
          //check if api_body is valid JSON
          let api_body = a.get('api_body');
          if (api_body) {
            try {
              JSON.parse(api_body);
            } catch (e) {
              error = 'invalid_api_body';
              return;
            }
          }

          a.set('id', id.underscore());

          delete a.isNew;

          step['actions'].push(a);
        });

        if (error) return;
      }

      steps.push(step);
    });

    if (error) {
      return { error };
    } else {
      return { steps };
    };
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
      return result.wizards.map(w => CustomWizard.create(w));
    });
  },

  submissions(wizardId) {
    return ajax(`/admin/wizards/submissions/${wizardId}`, {
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

      wizardProperties.forEach((p) => {
        props[p] = w[p];
      });

      if (w.steps && w.steps.length) {
        w.steps.forEach((s) => {
          // clean empty strings
          Object.keys(s).forEach((key) => (s[key] === '') && delete s[key]);

          let fields =  Ember.A();

          if (s.fields && s.fields.length) {
            s.fields.forEach((f) => {
              Object.keys(f).forEach((key) => (f[key] === '') && delete f[key]);

              const fieldParams = { isNew: false };
              let field = Ember.Object.create($.extend(f, fieldParams));

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
              const actionParams = { isNew: false };
              const action = Ember.Object.create($.extend(a, actionParams));
              actions.pushObject(action);
            });
          }

          steps.pushObject(Ember.Object.create({
            id: s.id,
            key: s.key,
            title: s.title,
            raw_description: s.raw_description,
            banner: s.banner,
            required_data: s.required_data,
            required_data_message: s.required_data_message,
            permitted_params: s.permitted_params,
            fields,
            actions,
            isNew: false
          }));
        });
      };
    } else {
      props['id'] = '';
      props['name'] = '';
      props['background'] = '';
      props['save_submissions'] = true;
      props['multiple_submissions'] = false;
      props['after_signup'] = false;
      props['after_time'] = false;
      props['required'] = false;
      props['prompt_completion'] = false;
      props['min_trust'] = 0;
      props['steps'] = Ember.A();
    };

    wizard.setProperties(props);

    return wizard;
  }
});

export default CustomWizard;
