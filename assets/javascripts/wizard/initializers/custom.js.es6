import { default as computed } from 'discourse-common/utils/decorators';
import { dasherize } from "@ember/string";

export default {
  name: 'custom-routes',

  initialize(app) {
    if (window.location.pathname.indexOf('/w/') < 0) return;

    const EmberObject = requirejs('@ember/object').default;
    const Router = requirejs('wizard/router').default;
    const ApplicationRoute = requirejs('wizard/routes/application').default;
    const ajax = requirejs('wizard/lib/ajax').ajax;
    const StepModel = requirejs('wizard/models/step').default;
    const CustomWizard = requirejs('discourse/plugins/discourse-custom-wizard/wizard/models/custom').default;
    const WizardStep = requirejs('wizard/components/wizard-step').default;
    const WizardField = requirejs('wizard/components/wizard-field').default;
    const getUrl = requirejs('discourse-common/lib/get-url').default;
    const FieldModel = requirejs('wizard/models/wizard-field').default;
    const autocomplete = requirejs('discourse/lib/autocomplete').default;
    const cook = requirejs('discourse/plugins/discourse-custom-wizard/wizard/lib/text-lite').cook;
    const Singleton = requirejs("discourse/mixins/singleton").default;
    const Store = requirejs("discourse/models/store").default;
    const registerRawHelpers = requirejs("discourse-common/lib/raw-handlebars-helpers").registerRawHelpers;
    const createHelperContext = requirejs("discourse-common/lib/helpers").createHelperContext;
    const RawHandlebars = requirejs("discourse-common/lib/raw-handlebars").default;
    const Site = requirejs("discourse/plugins/discourse-custom-wizard/wizard/models/site").default;
    const RestAdapter = requirejs("discourse/adapters/rest").default;

    Discourse.Model = EmberObject.extend();
    Discourse.__container__ = app.__container__;

    registerRawHelpers(RawHandlebars, Handlebars);

    // IE11 Polyfill - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/entries#Polyfill
    if (!Object.entries)
      Object.entries = function( obj ){
        var ownProps = Object.keys( obj ),
            i = ownProps.length,
            resArray = new Array(i); // preallocate the Array
        while (i--)
          resArray[i] = [ownProps[i], obj[ownProps[i]]];

        return resArray;
      };

    $.fn.autocomplete = autocomplete;

    const targets = ["controller", "component", "route", "model", "adapter"];

    const siteSettings = Wizard.SiteSettings;
    app.register("site-settings:main", siteSettings, { instantiate: false });
    createHelperContext(siteSettings);
    targets.forEach(t => app.inject(t, "siteSettings", "site-settings:main"));
    
    app.register("service:store", Store);
    targets.forEach(t => app.inject(t, "store", "service:store"));
    targets.forEach(t => app.inject(t, "appEvents", "service:app-events"));
    
    app.register("adapter:rest", RestAdapter);
    
    const site = Site.current();
    app.register("site:main", site, { instantiate: false });
    targets.forEach(t => app.inject(t, "site", "site:main"));
        
    site.set('can_create_tag', false);
        
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

      animateInvalidFields() {
        Ember.run.scheduleOnce('afterRender', () => {
          let $element = $('.invalid input[type=text], .invalid textarea, .invalid input[type=checkbox], .invalid .select-kit');
          
          if ($element.length) {
            $([document.documentElement, document.body]).animate({
              scrollTop: $element.offset().top - 200
            }, 400, function() {
              $element.wiggle(2, 100);
            });
          }
        });
      },

      ensureStartsAtTop: function() {
        window.scrollTo(0,0);
      }.observes('step.id'),

      showQuitButton: function() {
        const index = this.get('step.index');
        const required = this.get('wizard.required');
        return index === 0 && !required;
      }.property('step.index', 'wizard.required'),

      cookedTitle: function() {
        return cook(this.get('step.title'));
      }.property('step.title'),

      cookedDescription: function() {
        return cook(this.get('step.description'));
      }.property('step.description'),

      bannerImage: function() {
        const src = this.get('step.banner');
        if (!src) return;
        return getUrl(src);
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
              CustomWizard.finished(response);
            } else {
              this.sendAction('goNext', response);
            }
          })
          .catch(() => this.animateInvalidFields())
          .finally(() => this.set('saving', false));
      },
      
      keyPress(key) {
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

        this.get('fields').forEach(f => {
          if (f.type !== 'text_only') {
            fields[f.id] = f.value;
          }
        });
        
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
            this.animateInvalidFields();
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
      classNameBindings: ['field.id'],

      cookedDescription: function() {
        return cook(this.get('field.description'));
      }.property('field.description'),

      inputComponentName: function() {
        const type = this.get('field.type');
        const id = this.get('field.id');
        if (['text_only'].includes(type)) return false;
        return dasherize((type === 'component') ? id : `wizard-field-${type}`);
      }.property('field.type', 'field.id')
    });

    const StandardFieldValidation = [
      'text',
      'number',
      'textarea',
      'dropdown',
      'tag',
      'image',
      'user_selector',
      'text_only',
      'composer',
      'category',
      'group',
      'date',
      'time',
      'date_time'
    ];

    FieldModel.reopen({
      check() {
        if (this.customCheck) {
          return this.customCheck();
        }
        
        let valid = this.valid;

        if (!this.required) {
          this.setValid(true);
          return true;
        }

        const val = this.get('value');
        const type = this.get('type');
                  
        if (type === 'checkbox') {
          valid = val;
        } else if (type === 'upload') {
          valid = val && val.id > 0;
        } else if (StandardFieldValidation.indexOf(type) > -1) {
          valid = val && val.toString().length > 0;
        } else if (type === 'url') {
          valid = true;
        }
                    
        this.setValid(valid);

        return valid;
      }
    });
  }
};
