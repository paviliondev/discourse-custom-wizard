import Controller from "@ember/controller";
import { empty } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import { fmt } from "discourse/lib/computed";
import { inject as service } from "@ember/service";
import AdminWizardsColumnsModal from "../components/modal/admin-wizards-columns";
import CustomWizardAdmin from "../models/custom-wizard-admin";
import { formatModel } from "../lib/wizard-submission";

export default Controller.extend({
  modal: service(),
  downloadUrl: fmt("wizard.id", "/admin/wizards/submissions/%@/download"),
  noResults: empty("submissions"),
  page: 0,
  total: 0,

  loadMoreSubmissions() {
    const page = this.get("page");
    const wizardId = this.get("wizard.id");

    this.set("loadingMore", true);
    CustomWizardAdmin.submissions(wizardId, page)
      .then((result) => {
        if (result.submissions) {
          const { submissions } = formatModel(result);

          this.get("submissions").pushObjects(submissions);
        }
      })
      .finally(() => {
        this.set("loadingMore", false);
      });
  },

  @discourseComputed("submissions.[]", "fields.@each.enabled")
  displaySubmissions(submissions, fields) {
    let result = [];

    submissions.forEach((submission) => {
      let sub = {};

      Object.keys(submission).forEach((fieldId) => {
        if (fields.some((f) => f.id === fieldId && f.enabled)) {
          sub[fieldId] = submission[fieldId];
        }
      });
      result.push(sub);
    });

    return result;
  },

  actions: {
    loadMore() {
      if (!this.loadingMore && this.submissions.length < this.total) {
        this.set("page", this.get("page") + 1);
        this.loadMoreSubmissions();
      }
    },

    showEditColumnsModal() {
      return this.modal.show(AdminWizardsColumnsModal, {
        model: {
          columns: this.get("fields"),
          reset: () => {
            this.get("fields").forEach((field) => {
              field.set("enabled", true);
            });
          },
        },
      });
    },
  },
});
