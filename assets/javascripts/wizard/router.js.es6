import EmberRouter from "@ember/routing/router";
import getUrl from "discourse-common/lib/get-url";
import { isTesting } from "discourse-common/config/environment";

const Router = EmberRouter.extend({
  rootURL: isTesting() ? getUrl("/") : getUrl("/w/"),
  location: isTesting() ? "none" : "history",
});

Router.map(function () {
  this.route("wizard", { path: "/:wizard_id" }, function () {
    this.route("steps", { path: "/steps", resetNamespace: true });
    this.route("step", { path: "/steps/:step_id", resetNamespace: true });
  });
});

export default Router;
