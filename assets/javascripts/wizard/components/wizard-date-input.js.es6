import DateInput from "discourse/components/date-input";
import loadScript from "discourse/lib/load-script";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
/* global Pikaday:true */

export default DateInput.extend({
  useNativePicker: false,

  @discourseComputed()
  placeholder() {
    return this.format;
  },

  _loadPikadayPicker(container) {
    return loadScript("/javascripts/pikaday.js").then(() => {
      let defaultOptions = {
        field: this.element.querySelector(".date-picker"),
        container: container || this.element.querySelector(".picker-container"),
        bound: container === null,
        format: this.format,
        firstDay: 1,
        i18n: {
          previousMonth: I18n.t("dates.previous_month"),
          nextMonth: I18n.t("dates.next_month"),
          months: moment.months(),
          weekdays: moment.weekdays(),
          weekdaysShort: moment.weekdaysShort(),
        },
        onSelect: (date) => this._handleSelection(date),
      };

      if (this.relativeDate) {
        defaultOptions = Object.assign({}, defaultOptions, {
          minDate: moment(this.relativeDate).toDate(),
        });
      }

      return new Pikaday(Object.assign({}, defaultOptions, this._opts()));
    });
  },
});
