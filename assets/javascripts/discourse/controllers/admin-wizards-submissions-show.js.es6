import Controller from "@ember/controller";
import { empty } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import { fmt } from "discourse/lib/computed";
import showModal from "discourse/lib/show-modal";
import CustomWizard from "../models/custom-wizard";

export default Controller.extend({
  downloadUrl: fmt("wizard.id", "/admin/wizards/submissions/%@/download"),
  noResults: empty("submissions"),
  page: 0,
  total: 0,

  loadMoreSubmissions() {
    const page = this.get("page");
    const wizardId = this.get("wizard.id");

    this.set("loadingMore", true);
    CustomWizard.submissions(wizardId, page)
      .then((result) => {
        if (result.submissions) {
          this.get("submissions").pushObjects(result.submissions);
        }
      })
      .finally(() => {
        this.set("loadingMore", false);
      });
  },

  @discourseComputed("submissions", "fields.@each.enabled")
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
      return showModal("admin-wizards-columns", {
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
