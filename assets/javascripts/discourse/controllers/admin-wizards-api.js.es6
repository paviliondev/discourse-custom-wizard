import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import CustomWizardApi from '../models/custom-wizard-api';

export default Ember.Controller.extend({
  loadingSubscriptions: false,
  notAuthorized: Ember.computed.not('api.authorized'),
  authorizationTypes: ['oauth', 'basic'],
  isOauth: Ember.computed.equal('api.authType', 'oauth'),
  endpointMethods: ['GET', 'PUT', 'POST', 'PATCH', 'DELETE'],

  actions: {
    addParam() {
      this.get('api.authParams').pushObject({});
    },

    removeParam(param) {
      this.get('api.authParams').removeObject(param);
    },

    addEndpoint() {
      this.get('api.endpoints').pushObject({});
    },

    removeEndpoint(endpoint) {
      this.get('api.endpoints').removeObject(endpoint);
    },

    authorize() {
      const api = this.get('api');
      const { authType, authUrl, authParams } = api;
      let query = '?';

      if (authType === 'oauth') {
        query += `client_id=${api.get('clientId')}&redirect_uri=${encodeURIComponent(api.get('redirectUri'))}&response_type=code`;

        if (authParams) {
          authParams.forEach(p => {
            query += `&${p.key}=${encodeURIComponent(p.value)}`;
          });
        }
      } else {
        // basic auth
      }

      window.location.href = authUrl + query;
    },

    save() {
      const api = this.get('api');
      const service = api.get('service');

      let data = {};

      data['auth_type'] = api.get('authType');
      data['auth_url'] = api.get('authUrl');

      if (data.auth_type === 'oauth') {
        data['client_id'] = api.get('clientId');
        data['client_secret'] = api.get('clientSecret');

        let params = api.get('authParams');

        if (params) {
          data['auth_params'] = JSON.stringify(params);
        }

        data['token_url'] = api.get('tokenUrl');
      } else {
        data['username'] = api.get('username');
        data['password'] = api.get('password');
      }

      const endpoints = api.get('endpoints');
      if (endpoints.length) {
        data['endpoints'] = JSON.stringify(endpoints);
      }

      this.set('savingApi', true);

      ajax(`/admin/wizards/apis/${service}`, {
        type: 'PUT',
        data
      }).catch(popupAjaxError)
        .then(result => {
          if (result.success) {
            this.set('api', CustomWizardApi.create(result.api));
          }
        }).finally(() => this.set('savingApi', false));
    }
  }
});
