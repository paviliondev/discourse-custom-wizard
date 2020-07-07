import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import CustomWizardApi from '../models/custom-wizard-api';
import { default as discourseComputed } from 'discourse-common/utils/decorators';
import { not, and, equal } from "@ember/object/computed";
import { selectKitContent } from '../lib/wizard';
import Controller from "@ember/controller";
import I18n from "I18n";

export default Controller.extend({
  queryParams: ['refresh_list'],
  loadingSubscriptions: false,
  notAuthorized: not('api.authorized'),
  endpointMethods: selectKitContent(['GET', 'PUT', 'POST', 'PATCH', 'DELETE']),
  showRemove: not('isNew'),
  showRedirectUri: and('threeLeggedOauth', 'api.name'),
  responseIcon: null,
  contentTypes: selectKitContent(['application/json', 'application/x-www-form-urlencoded']),
  successCodes: selectKitContent([100, 101, 102, 200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 303, 304, 305, 306, 307, 308]),

  @discourseComputed('saveDisabled', 'api.authType', 'api.authUrl', 'api.tokenUrl', 'api.clientId', 'api.clientSecret', 'threeLeggedOauth')
  authDisabled(saveDisabled, authType, authUrl, tokenUrl, clientId, clientSecret, threeLeggedOauth) {
    if (saveDisabled || !authType || !tokenUrl || !clientId || !clientSecret) return true;
    if (threeLeggedOauth) return !authUrl;
    return false;
  },

  @discourseComputed('api.name', 'api.authType')
  saveDisabled(name, authType) {
    return !name || !authType;
  },

  authorizationTypes: selectKitContent(['none', 'basic', 'oauth_2', 'oauth_3']),
  isBasicAuth: equal('api.authType', 'basic'),

  @discourseComputed('api.authType')
  isOauth(authType) {
    return authType && authType.indexOf('oauth') > -1;
  },

  twoLeggedOauth: equal('api.authType', 'oauth_2'),
  threeLeggedOauth: equal('api.authType', 'oauth_3'),

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
      const { name, authType, authUrl, authParams } = api;

      this.set('authErrorMessage', '');

      if (authType === 'oauth_2') {
        this.set('authorizing', true);
        ajax(`/admin/wizards/apis/${name.underscore()}/authorize`).catch(popupAjaxError)
          .then(result => {
            if (result.success) {
              this.set('api', CustomWizardApi.create(result.api));
            } else if (result.failed && result.message) {
              this.set('authErrorMessage', result.message);
            } else {
              this.set('authErrorMessage', 'Authorization Failed');
            }
            setTimeout(() => {
              this.set('authErrorMessage', '');
            }, 6000);
          }).finally(() => this.set('authorizing', false));
      } else if (authType === 'oauth_3') {
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
      }
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

      if (authType === 'basic') {
        requiredParams = ['username', 'password'];
      } else if (authType === 'oauth_2') {
        requiredParams = ['tokenUrl', 'clientId', 'clientSecret'];
      } else if (authType === 'oauth_3') {
        requiredParams = ['authUrl', 'tokenUrl', 'clientId', 'clientSecret'];
      }

      if (requiredParams) {
        for (let rp of requiredParams) {
          if (!api[rp]) {
            let key = rp.replace('auth', '');
            error = `${I18n.t(`admin.wizard.api.auth.${key.underscore()}`)} is required for ${authType}`;
            break;
          }
          data[rp.underscore()] = api[rp];
        }
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

      ajax(`/admin/wizards/api/${name.underscore()}`, {
        type: 'PUT',
        data
      }).catch(popupAjaxError)
        .then(result => {
          if (result.success) {
            this.send('afterSave', result.api.name);
          } else {
            this.set('responseIcon', 'times');
          }
        }).finally(() => this.set('updating', false));
    },

    remove() {
      const name = this.get('api.name');
      if (!name) return;

      this.set('updating', true);

      ajax(`/admin/wizards/api/${name.underscore()}`, {
        type: 'DELETE'
      }).catch(popupAjaxError)
        .then(result => {
          if (result.success) {
            this.send('afterDestroy');
          }
        }).finally(() => this.set('updating', false));
    },

    clearLogs() {
      const name = this.get('api.name');
      if (!name) return;

      ajax(`/admin/wizards/api/${name.underscore()}/logs`, {
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
