import { buildResolver } from "discourse-common/resolver";

export default Ember.Application.extend({
  rootElement: '#custom-wizard-main',
  Resolver: buildResolver("wizard"),

  start() {
    Object.keys(requirejs._eak_seen).forEach(key => {
      if (/\/initializers\//.test(key)) {
        const module = requirejs(key, null, null, true);
        if (!module) {
          throw new Error(key + " must export an initializer.");
        }
        this.initializer(module.default);
      }
    });
    
    Object.keys(requirejs._eak_seen).forEach((key) => {
      if (/\/pre\-initializers\//.test(key)) {
        const module = requirejs(key, null, null, true);
        if (!module) {
          throw new Error(key + " must export an initializer.");
        }
        
        const init = module.default;
        const oldInitialize = init.initialize;
        init.initialize = () => {
          oldInitialize.call(this, this.__container__, this);
        };

        this.initializer(init);
      }
    });
  }
});
