import Controller from "@ember/controller";
import { fmt } from "discourse/lib/computed";
import { empty } from "@ember/object/computed";
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
  
  
  @discourseComputed('submissions', 'fields.@each.enabled')
  displaySubmissions(submissions, fields) {
    return submissions.map(submission => {
      let field = fields.find(f => Object.keys(submission).includes(f.id));
      if (!field.enabled) {
        submission.delete(field.id);
      };
      return submission;
    });
  },

  actions: {
    loadMore() {
      if (!this.loadingMore && this.submissions.length < this.total) {
        this.set("page", this.get("page") + 1);
        this.loadMoreSubmissions();
      }
    },
  },
});
