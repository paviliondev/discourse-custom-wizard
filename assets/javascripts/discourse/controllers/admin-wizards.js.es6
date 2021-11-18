import Controller, { inject as controller } from "@ember/controller";
import { isPresent } from "@ember/utils";
import { A } from "@ember/array";

export default Controller.extend({
  adminWizardsNotices: controller(),

  unsubscribe() {
    this.messageBus.unsubscribe("/custom-wizard/notices");
  },

  subscribe() {
    this.unsubscribe();
    this.messageBus.subscribe("/custom-wizard/notices", (data) => {
      if (isPresent(data.active_notice_count)) {
        this.set("activeNoticeCount", data.active_notice_count);
        this.adminWizardsNotices.setProperties({
          notices: A(),
          page: 0,
          canLoadMore: true,
        });
        this.adminWizardsNotices.loadMoreNotices();
      }
    });
  },
});
