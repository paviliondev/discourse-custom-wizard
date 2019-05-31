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
      if (this.get('api.authParams') == undefined) {
        this.set('api.authParams',[]);
      };
      this.get('api.authParams').pushObject({});
    },

    removeParam(param) {
      this.get('api.authParams').removeObject(param);
    },

    addEndpoint() {
      if (this.get('api.endpoints') == undefined) {
        this.set('api.endpoints',[]);
      };
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
        query += `client_id=${api.clientId}&redirect_uri=${encodeURIComponent(api.redirectUri)}&response_type=code`;

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
      const service = api.service;

      let data = {};

      data['auth_type'] = api.authType;
      data['auth_url'] = api.authUrl;

      if (data.auth_type === 'oauth') {
        data['client_id'] = api.clientId;
        data['client_secret'] = api.clientSecret;

        let params = api.authParams;

        if (params) {
          data['auth_params'] = JSON.stringify(params);
        }

        data['token_url'] = api.tokenUrl;
      } else {
        data['username'] = api.username;
        data['password'] = api.password;
      }

      const endpoints = api.endpoints;
      if (endpoints != undefined) {
        if (endpoints.length) {
          data['endpoints'] = JSON.stringify(endpoints);
        }
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
