export default function () {
  this.route(
    "customWizard",
    { path: "/w/:wizard_id", resetNamespace: true },
    function () {
      this.route("customWizardStep", {
        path: "/steps/:step_id",
        resetNamespace: true,
      });
    }
  );
}
