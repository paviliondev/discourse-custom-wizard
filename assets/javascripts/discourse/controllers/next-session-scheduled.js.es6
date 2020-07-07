import { default as discourseComputed } from 'discourse-common/utils/decorators';
import Controller from "@ember/controller";

export default Controller.extend({
  title: 'admin.wizard.after_time_modal.title',

  setup() {
    this.set('bufferedDateTime', moment(this.model.dateTime));
  },

  @discourseComputed('bufferedDateTime')
  submitDisabled(dateTime) {
    return moment().isAfter(dateTime);
  },

  actions: {
    submit() {
      const dateTime = this.get('bufferedDateTime');
      this.get('model.update')(moment(dateTime).utc().toISOString());
      this.send("closeModal");
    },
    
    dateTimeChanged(dateTime) {
      this.set('bufferedDateTime', dateTime);
    }
  }
});
