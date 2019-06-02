import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import CustomWizardApi from '../models/custom-wizard-api';
import { default as computed, observes } from 'ember-addons/ember-computed-decorators';
import DiscourseURL from 'discourse/lib/url';

export default Ember.Controller.extend({
  queryParams: ['refresh_list'],
  loadingSubscriptions: false,
  notAuthorized: Ember.computed.not('api.authorized'),
  authorizationTypes: ['oauth', 'basic'],
  isOauth: Ember.computed.equal('api.authType', 'oauth'),
  isBasicAuth: Ember.computed.equal('api.authType', 'basic'),
  endpointMethods: ['GET', 'PUT', 'POST', 'PATCH', 'DELETE'],
  showRemove: Ember.computed.not('isNew'),

  @computed('saveDisabled', 'api.authType', 'api.authUrl')
  authDisabled(saveDisabled, authType, authUrl) {
    return saveDisabled || !authType || !authUrl;
  },

  @computed('api.name', 'api.authType')
  saveDisabled(name, authType) {
    return !name || !authType;
  },

  @observes('api.title')
  titleWatcher() {
    const title = this.get('api.title');

    if (this.get('originalTitle')) {
      this.set('originalTitle', title);
    }
  },

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

      if (authType !== 'oauth') return;

      let query = '?';

      query += `client_id=${api.clientId}`;
      query += `&redirect_uri=${encodeURIComponent(api.redirectUri)}`;
      query += `&response_type=code`;

      if (authParams) {
        authParams.forEach(p => {
          query += `&${p.key}=${encodeURIComponent(p.value)}`;
        });
      }

      window.location.href = authUrl + query;
    },

    save() {
      const api = this.get('api');
      const name = api.name;
      const authType = api.authType;
      let refreshList = false;

      if (!name || !authType) return;

      let data = {
        auth_type: authType
      };

      if (api.title) data['title'] = api.title;

      if (api.get('isNew') || (api.title !== this.get('originalTitle'))) {
        refreshList = true;
      }

      if (api.get('isNew')) {
        data['new'] = true;
      };

      if (authType === 'oauth') {
        data['auth_url'] = api.authUrl;
        data['client_id'] = api.clientId;
        data['client_secret'] = api.clientSecret;

        let params = api.authParams;

        if (params) {
          data['auth_params'] = JSON.stringify(params);
        }

        data['token_url'] = api.tokenUrl;
      } else if (authType === 'basic') {
        data['username'] = api.username;
        data['password'] = api.password;
      }

      const endpoints = api.endpoints;

      if (endpoints.length) {
        data['endpoints'] = JSON.stringify(endpoints);
      }

      this.set('updating', true);

      ajax(`/admin/wizards/apis/${name.underscore()}`, {
        type: 'PUT',
        data
      }).catch(popupAjaxError)
        .then(result => {
          if (result.success) {
            if (refreshList) {
              this.transitionToRoute('adminWizardsApi', result.api.name.dasherize()).then(() => {
                this.send('refreshModel');
              });
            } else {
              this.set('api', CustomWizardApi.create(result.api));
            }
          }
        }).finally(() => this.set('updating', false));
    },

    remove() {
      const name = this.get('api.name');
      if (!name) return;

      this.set('updating', true);

      ajax(`/admin/wizards/apis/${name.underscore()}`, {
        type: 'DELETE'
      }).catch(popupAjaxError)
        .then(result => {
          if (result.success) {
            DiscourseURL.routeTo('/admin/wizards/apis?refresh=true');
          }
        }).finally(() => this.set('updating', false));
    }
  }
});
