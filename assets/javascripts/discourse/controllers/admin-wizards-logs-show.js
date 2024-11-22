import discourseComputed from "discourse-common/utils/decorators";
import { notEmpty } from "@ember/object/computed";
import CustomWizardLogs from "../models/custom-wizard-logs";
import Controller from "@ember/controller";

export default Controller.extend({
  refreshing: false,
  hasLogs: notEmpty("logs"),
  page: 0,
  canLoadMore: true,
  logs: [],
  messageKey: "viewing",

  loadLogs() {
    if (!this.canLoadMore) {
      return;
    }
    const page = this.get("page");
    const wizardId = this.get("wizard.id");

    this.set("refreshing", true);

    CustomWizardLogs.list(wizardId, page)
      .then((result) => {
        this.set("logs", this.logs.concat(result.logs));
      })
      .finally(() => this.set("refreshing", false));
  },

  @discourseComputed("hasLogs", "refreshing")
  noResults(hasLogs, refreshing) {
    return !hasLogs && !refreshing;
  },

  actions: {
    loadMore() {
      if (!this.loadingMore && this.logs.length < this.total) {
        this.set("page", (this.page += 1));
        this.loadLogs();
      }
    },

    refresh() {
      this.setProperties({
        canLoadMore: true,
        page: 0,
        logs: [],
      });
      this.loadLogs();
    },
  },
});
