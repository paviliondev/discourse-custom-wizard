import { ajax } from 'discourse/lib/ajax';
import { default as computed } from 'ember-addons/ember-computed-decorators';

const CustomWizardApi = Discourse.Model.extend({
  @computed('service')
  redirectUri(service) {
    const baseUrl = location.protocol+'//'+location.hostname+(location.port ? ':'+location.port: '');
    return baseUrl + `/admin/wizards/apis/${service}/redirect`;
  }
});

CustomWizardApi.reopenClass({
  create(params) {
    const api = this._super.apply(this);
    api.setProperties({
      service: params.service,
      authType: params.auth_type,
      authUrl: params.auth_url,
      tokenUrl: params.token_url,
      clientId: params.client_id,
      clientSecret: params.client_secret,
      authParams: Ember.A(params.auth_params),
      authorized: params.authorized,
      accessToken: params.access_token,
      refreshToken: params.refresh_token,
      code: params.code,
      tokenExpiresAt: params.token_expires_at,
      tokenRefreshAt: params.token_refresh_at
    });
    return api;
  },

  find(service) {
    return ajax(`/admin/wizards/apis/${service}`, {
      type: 'GET'
    }).then(result => {
      return result;
    });
  },

  list() {
    return ajax("/admin/wizards/apis", {
      type: 'GET'
    }).then(result => {
      return result;
    });
  }
});

export default CustomWizardApi;
