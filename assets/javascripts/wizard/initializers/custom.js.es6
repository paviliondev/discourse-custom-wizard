
export default {
  name: 'custom-routes',

  initialize(container, app) {
    if (app.get('rootElement') !== '#custom-wizard-main') return;

    const WizardApplicationRoute = requirejs('wizard/routes/application').default;
    const findCustomWizard = requirejs('discourse/plugins/discourse-custom-wizard/wizard/models/custom').findCustomWizard;
    const Router = requirejs('wizard/router').default;
    const ajax = requirejs('wizard/lib/ajax').ajax;
    const StepRoute = requirejs('wizard/routes/step').default;
    const StepModel = requirejs('wizard/models/step').default;

    Router.map(function() {
      this.route('custom', { path: '/custom/:id' }, function() {
        this.route('step', { path: '/steps/:step_id' });
      });
    });

    WizardApplicationRoute.reopen({
      model() {
        const customParams = this.paramsFor('custom');
        return findCustomWizard(customParams.id);
      },

      afterModel(model) {
        return ajax({
          url: `/site/basic-info`,
          type: 'GET',
        }).then((result) => {
          return model.set('siteInfo', result);
        });
      },

      setupController(controller, model) {
        controller.setProperties({
          customWizard: true,
          siteInfo: model.get('siteInfo')
        });
      }
    });

    StepModel.reopen({
      save() {
        const fields = {};
        this.get('fields').forEach(f => fields[f.id] = f.value);
        return ajax({
          url: `/wizard/custom/${this.get('wizardId')}/steps/${this.get('id')}`,
          type: 'PUT',
          data: { fields }
        }).catch(response => {
          response.responseJSON.errors.forEach(err => this.fieldError(err.field, err.description));
          throw response;
        });
      }
    });

    StepRoute.reopen({
      afterModel(model) {
        const wizard = this.modelFor('application');
        return model.set("wizardId", wizard.id);
      }
    });
  }
};
