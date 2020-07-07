import { default as computed } from 'discourse-common/utils/decorators';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { ajax } from 'discourse/lib/ajax';
import { notEmpty } from "@ember/object/computed";
import CustomWizardLogs from '../models/custom-wizard-logs';
import Controller from "@ember/controller";

export default Controller.extend({
  refreshing: false,
  hasLogs: notEmpty("logs"),
  page: 0,
  canLoadMore: true,
  logs: [],
  
  loadLogs() {
    if (!this.canLoadMore) return;

    this.set("refreshing", true);
        
    CustomWizardLogs.list()
      .then(result => {
        if (!result || result.length === 0) {
          this.set('canLoadMore', false);
        }
        this.set("logs", this.logs.concat(result));
      })
      .finally(() => this.set("refreshing", false));
  },
  
  @computed('hasLogs', 'refreshing')
  noResults(hasLogs, refreshing) {
    return !hasLogs && !refreshing;
  },
  
  actions: {
    loadMore() {
      this.set('page', this.page += 1);
      this.loadLogs();
    },
    
    refresh() {
      this.setProperties({
        canLoadMore: true,
        page: 0,
        logs: []
      })
      this.loadLogs();
    }
  }
});