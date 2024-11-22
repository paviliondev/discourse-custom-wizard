import DiscourseRoute from "discourse/routes/discourse";
import CustomWizardApi from "../models/custom-wizard-api";
import { inject as service } from "@ember/service";

export default DiscourseRoute.extend({
  router: service(),

  model() {
    return CustomWizardApi.list();
  },

  setupController(controller, model) {
    const showParams = this.paramsFor("adminWizardsApiShow");
    const apiName = showParams.name === "create" ? null : showParams.name;
    const apiList = (model || []).map((api) => {
      return {
        id: api.name,
        name: api.title,
      };
    });

    controller.setProperties({
      apiName,
      apiList,
    });
  },

  actions: {
    changeApi(apiName) {
      this.controllerFor("adminWizardsApi").set("apiName", apiName);
      this.router.transitionTo("adminWizardsApiShow", apiName);
    },

    afterDestroy() {
      this.router.transitionTo("adminWizardsApi").then(() => this.refresh());
    },

    afterSave(apiName) {
      this.refresh().then(() => this.send("changeApi", apiName));
    },

    createApi() {
      this.controllerFor("adminWizardsApi").set("apiName", "create");
      this.router.transitionTo("adminWizardsApiShow", "create");
    },
  },
});
