import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from 'discourse/lib/ajax';
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model() {
    return ajax('/admin/wizards/custom-fields');
  },
  
  setupController(controller, model) {
    controller.set('customFields', A(model || []));
  }
});