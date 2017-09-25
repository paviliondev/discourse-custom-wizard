import { findCustomWizard } from '../models/custom-wizard';

export default Ember.Route.extend({
  model(params) {
    return findCustomWizard(params.name);
  }
});
