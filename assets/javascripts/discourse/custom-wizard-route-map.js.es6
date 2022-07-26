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

  this.route(
    "adminWizards",
    { path: "/wizards", resetNamespace: true },
    function () {
      this.route(
        "adminWizardsWizard",
        { path: "/wizard/", resetNamespace: true },
        function () {
          this.route("adminWizardsWizardShow", {
            path: "/:wizardId/",
            resetNamespace: true,
          });
        }
      );

      this.route("adminWizardsCustomFields", {
        path: "/custom-fields",
        resetNamespace: true,
      });

      this.route(
        "adminWizardsSubmissions",
        { path: "/submissions", resetNamespace: true },
        function () {
          this.route("adminWizardsSubmissionsShow", {
            path: "/:wizardId/",
            resetNamespace: true,
          });
        }
      );

      this.route(
        "adminWizardsApi",
        { path: "/api", resetNamespace: true },
        function () {
          this.route("adminWizardsApiShow", {
            path: "/:name",
            resetNamespace: true,
          });
        }
      );

      this.route("adminWizardsLogs", { path: "/logs", resetNamespace: true });

      this.route("adminWizardsManager", {
        path: "/manager",
        resetNamespace: true,
      });
    }
  );
}
