import Router from 'wizard/router';

export default {
  name: 'custom-routes',

  initialize() {
    Router.map(function() {
      this.route('custom', { path: '/custom/:name' }, function() {
        this.route('step', { path: '/steps/:step_id' });
      });
    });
  }
};
