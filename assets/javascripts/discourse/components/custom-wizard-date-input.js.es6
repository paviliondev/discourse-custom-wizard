import DateInput from "discourse/components/date-input";
import discourseComputed from "discourse-common/utils/decorators";

export default DateInput.extend({
  useNativePicker: false,
  classNameBindings: ["fieldClass"],

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
