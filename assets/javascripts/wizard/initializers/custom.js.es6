export default {
  name: 'custom-routes',

  initialize() {
    if (window.location.pathname.indexOf('/w/') < 0) return;

    const Router = requirejs('wizard/router').default;
    const ApplicationRoute = requirejs('wizard/routes/application').default;
    const ajax = requirejs('wizard/lib/ajax').ajax;
    const StepModel = requirejs('wizard/models/step').default;
    const WizardStep = requirejs('wizard/components/wizard-step').default;
    const WizardField = requirejs('wizard/components/wizard-field').default;
    const getUrl = requirejs('discourse-common/lib/get-url').default;
    const FieldModel = requirejs('wizard/models/wizard-field').default;
    const autocomplete = requirejs('discourse/lib/autocomplete').default;

    $.fn.autocomplete = autocomplete;

    // this is for discourse/lib/utilities.avatarImg;
    Discourse.getURLWithCDN = getUrl;

    Router.reopen({
      rootURL: getUrl('/w/')
    });

    Router.map(function() {
      this.route('custom', { path: '/:wizard_id' }, function() {
        this.route('steps');
        this.route('step', { path: '/steps/:step_id' });
      });
    });

    ApplicationRoute.reopen({
      redirect() {
        this.transitionTo('custom');
      },

      model() {}
    });

    WizardStep.reopen({
      classNameBindings: ['step.id'],

      ensureStartsAtTop: function() {
        window.scrollTo(0,0);
      }.observes('step.id'),

      showQuitButton: function() {
        const index = this.get('step.index');
        const required = this.get('wizard.required');
        return index === 0 && !required;
      }.property('step.index', 'wizard.required'),

      bannerImage: function() {
        const src = this.get('step.banner');
        if (!src) return;

        if (src.indexOf('/uploads/') > -1 || src.indexOf('/plugins/') > -1) {
          return getUrl(src);
        } else {
          return getUrl(`/images/wizard/${src}`);
        };
      }.property('step.banner'),

      handleMessage: function() {
        const message = this.get('step.message');
        this.sendAction('showMessage', message);
      }.observes('step.message'),

      advance() {
        this.set('saving', true);
        this.get('step').save()
          .then(response => {
            if (this.get('finalStep')) {
              this.get('wizard').finished(response);
            } else {
              this.sendAction('goNext', response);
            }
          })
          .catch(() => this.animateInvalidFields())
          .finally(() => this.set('saving', false));
      },

      actions: {
        quit() {
          this.get('wizard').skip();
        },

        done() {
          this.set('finalStep', true);
          this.send('nextStep');
        },

        showMessage(message) {
          this.sendAction('showMessage', message);
        }
      }
    });

    StepModel.reopen({
      save() {
        const wizardId = this.get('wizardId');
        const fields = {};
        this.get('fields').forEach(f => fields[f.id] = f.value);
        return ajax({
          url: `/w/${wizardId}/steps/${this.get('id')}`,
          type: 'PUT',
          data: { fields }
        }).catch(response => {
          if (response && response.responseJSON && response.responseJSON.errors) {
            let wizardErrors = [];
            response.responseJSON.errors.forEach(err => {
              if (err.field === wizardId) {
                wizardErrors.push(err.description);
              } else if (err.field) {
                this.fieldError(err.field, err.description);
              } else if (err) {
                wizardErrors.push(err);
              }
            });
            if (wizardErrors.length) {
              this.handleWizardError(wizardErrors.join('\n'));
            }
            throw response;
          }

          if (response && response.responseText) {
            const responseText = response.responseText;
            const start = responseText.indexOf('>') + 1;
            const end = responseText.indexOf('plugins');
            const message = responseText.substring(start, end);
            this.handleWizardError(message);
            throw message;
          }
        });
      },

      handleWizardError(message) {
        this.set('message', {
          state: 'error',
          text: message
        });
        Ember.run.later(() => this.set('message', null), 6000);
      }
    });

    WizardField.reopen({
      inputComponentName: function() {
        const type = this.get('field.type');
        const id = this.get('field.id');
        if (type === 'text-only') return false;
        return (type === 'component') ? Ember.String.dasherize(id) : `wizard-field-${type}`;
      }.property('field.type', 'field.id')
    });

    const StandardFields = ['text', 'textarea', 'dropdown', 'image', 'checkbox', 'user-selector', 'text-only'];

    FieldModel.reopen({
      hasCustomCheck: false,

      customCheck() {
        return true;
      },

      check() {
        let valid = this.get('valid');

        if (!this.get('required')) {
          this.setValid(true);
          return true;
        }

        const hasCustomCheck = this.get('hasCustomCheck');
        if (hasCustomCheck) {
          valid = this.customCheck();
        } else {
          const val = this.get('value');
          const type = this.get('type');
          if (type === 'checkbox') {
            valid = val;
          } else if (StandardFields.indexOf(type) > -1) {
            valid = val && val.length > 0;
          }
        }

        this.setValid(valid);

        return valid;
      }
    });
  }
};
