import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import CustomWizardApi from '../models/custom-wizard-api';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  queryParams: ['refresh_list'],
  loadingSubscriptions: false,
  notAuthorized: Ember.computed.not('api.authorized'),
  authorizationTypes: ['oauth', 'basic'],
  isOauth: Ember.computed.equal('api.authType', 'oauth'),
  isBasicAuth: Ember.computed.equal('api.authType', 'basic'),
  endpointMethods: ['GET', 'PUT', 'POST', 'PATCH', 'DELETE'],
  showRemove: Ember.computed.not('isNew'),
  responseIcon: null,

  @computed('saveDisabled', 'api.authType', 'api.authUrl', 'api.clientId', 'api.clientSecret')
  authDisabled(saveDisabled, authType, authUrl, clientId, clientSecret) {
    return saveDisabled || !authType || !authUrl || !clientId || !clientSecret;
  },

  @computed('api.name', 'api.authType')
  saveDisabled(name, authType) {
    return !name || !authType;
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
      let error;

      if (!name || !authType) return;

      let data = {
        auth_type: authType
      };

      if (api.title) data['title'] = api.title;

      const originalTitle = this.get('api.originalTitle');
      if (api.get('isNew') || (originalTitle && (api.title !== originalTitle))) {
        refreshList = true;
      }

      if (api.get('isNew')) {
        data['new'] = true;
      };

      let requiredParams;

      if (authType === 'oauth') {
        requiredParams = ['authUrl', 'tokenUrl', 'clientId', 'clientSecret'];
      } else if (authType === 'basic') {
        requiredParams = ['username', 'password'];
      }

      for (let rp of requiredParams) {
        if (!api[rp]) {
          let key = rp.replace('auth', '');
          error = `${I18n.t(`admin.wizard.api.auth.${key.underscore()}`)} is required for ${authType}`;
          break;
        }
        data[rp.underscore()] = api[rp];
      }

      const params = api.authParams;
      if (params.length) {
        data['auth_params'] = JSON.stringify(params);
      }

      const endpoints = api.endpoints;
      if (endpoints.length) {
        for (let e of endpoints) {
          if (!e.name) {
            error = 'Every endpoint must have a name';
            break;
          }
        }
        data['endpoints'] = JSON.stringify(endpoints);
      }

      if (error) {
        this.set('error', error);
        setTimeout(() => {
          this.set('error', '');
        }, 6000);
        return;
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
              this.set('responseIcon', 'check');
            }
          } else {
            this.set('responseIcon', 'times');
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
            this.transitionToRoute('adminWizardsApis').then(() => {
              this.send('refreshModel');
            });
          }
        }).finally(() => this.set('updating', false));
    },

    clearLogs() {
      ajax(`/admin/wizards/apis/logs/${name.underscore()}`, {
        type: 'DELETE'
      }).catch(popupAjaxError)
        .then(result => {
          if (result.success) {
            this.transitionToRoute('adminWizardsApis').then(() => {
              this.send('refreshModel');
            });
          }
        }).finally(() => this.set('updating', false));
    }
  }
});
