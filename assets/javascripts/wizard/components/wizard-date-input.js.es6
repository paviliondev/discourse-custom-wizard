import DateInput from "discourse/components/date-input";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

export default DateInput.extend({
  useNativePicker: false,

  @discourseComputed()
  placeholder() {
    return this.format;
  },
});
