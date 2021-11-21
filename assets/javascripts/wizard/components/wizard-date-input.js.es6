import DateInput from "discourse/components/date-input";
import discourseComputed from "discourse-common/utils/decorators";

export default DateInput.extend({
  useNativePicker: false,

  @discourseComputed()
  placeholder() {
    return this.format;
  },
  _opts() {
    return {
      format: this.format || "LL",
    };
  },
});
