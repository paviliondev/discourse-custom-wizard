import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  title: 'admin.wizard.after_time_modal.title',

  setup() {
    const dateTime = this.get('model.dateTime');
    const ROUNDING = 30 * 60 * 1000;
    const nextInterval = moment(Math.ceil((+moment()) / ROUNDING) * ROUNDING);
    const mDateTime = dateTime ? moment(dateTime) : nextInterval;
    const mDateTimeLocal = mDateTime.local();
    const date = mDateTimeLocal.format('YYYY-MM-DD');
    const time = mDateTimeLocal.format('HH:mm');

    this.setProperties({ date, time });

    Ember.run.scheduleOnce('afterRender', this, () => {
      const $timePicker = $("#time-picker");
      $timePicker.timepicker({ timeFormat: 'H:i' });
      $timePicker.timepicker('setTime', time);
      $timePicker.change(() => this.set('time', $timePicker.val()));
    });
  },

  @computed('date', 'time')
  dateTime: function(date, time) {
    return moment(date + 'T' + time).format();
  },

  @computed('dateTime')
  submitDisabled(dateTime) {
    return moment().isAfter(dateTime);
  },

  resetProperties() {
    this.setProperties({
      date: null,
      time: null
    });
  },

  actions: {
    clear() {
      this.resetProperties();
      this.get('model.update')(null);
    },

    submit() {
      const dateTime = this.get('dateTime');
      const formatted = moment(dateTime).utc().toISOString();
      this.get('model.update')(formatted);
      this.resetProperties();
      this.send("closeModal");
    }
  }
});
