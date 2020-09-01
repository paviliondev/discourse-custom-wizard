(function() {
  var wizard = require('discourse/plugins/discourse-custom-wizard/wizard/custom-wizard').default.create();
  wizard.start();
  
  Object.keys(Ember.TEMPLATES).forEach(k => {
    if (k.indexOf("select-kit") === 0) {
      let template = Ember.TEMPLATES[k];
      define(k, () => template);
    }
  });
})();
