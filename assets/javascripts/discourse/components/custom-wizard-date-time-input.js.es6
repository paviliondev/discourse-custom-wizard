import DateTimeInput from "discourse/components/date-time-input";
import discourseComputed from "discourse-common/utils/decorators";

export default DateTimeInput.extend({
  @discourseComputed("timeFirst", "tabindex")
  timeTabindex(timeFirst, tabindex) {
    return timeFirst ? tabindex : tabindex + 1;
  },

  @discourseComputed("timeFirst", "tabindex")
  dateTabindex(timeFirst, tabindex) {
    return timeFirst ? tabindex + 1 : tabindex;
  },
});
