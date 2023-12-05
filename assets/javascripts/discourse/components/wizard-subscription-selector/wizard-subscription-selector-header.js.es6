import SingleSelectHeaderComponent from "select-kit/components/select-kit/single-select-header";
import { computed } from "@ember/object";
import { reads } from "@ember/object/computed";

export default SingleSelectHeaderComponent.extend({
  classNames: ["combo-box-header", "wizard-subscription-selector-header"],
  caretUpIcon: reads("selectKit.options.caretUpIcon"),
  caretDownIcon: reads("selectKit.options.caretDownIcon"),
  caretIcon: computed(
    "selectKit.isExpanded",
    "caretUpIcon",
    "caretDownIcon",
    function () {
      return this.selectKit.isExpanded ? this.caretUpIcon : this.caretDownIcon;
    }
  ),
});
