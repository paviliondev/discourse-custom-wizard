import WizardApplication from 'wizard/wizard';

export default WizardApplication.extend({
  rootElement: '#custom-wizard-main',

  start() {
    Object.keys(requirejs._eak_seen).forEach(key => {
      if (/\/initializers\//.test(key)) {
        console.log('running initializer', key);
        const module = requirejs(key, null, null, true);
        if (!module) { throw new Error(key + ' must export an initializer.'); }
        this.initializer(module.default);
      }
    });
  }
});
