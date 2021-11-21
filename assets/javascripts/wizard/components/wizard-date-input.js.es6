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
});
