import { default as discourseComputed } from "discourse-common/utils/decorators";
import SelectKitRowComponent from "select-kit/components/select-kit/select-kit-row";

export default SelectKitRowComponent.extend({
  classNameBindings: ["isDisabled:disabled"],

  @discourseComputed("item")
  isDisabled() {
    return this.item.disabled;
  },

  click(event) {
    event.preventDefault();
    event.stopPropagation();
    if (!this.item.disabled) {
      this.selectKit.select(this.rowValue, this.item);
    }
    return false;
  },
});
