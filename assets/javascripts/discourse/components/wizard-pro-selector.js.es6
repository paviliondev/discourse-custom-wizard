import SingleSelectComponent from "select-kit/components/single-select";
import { computed } from "@ember/object";

export default SingleSelectComponent.extend({
  classNames: ["combo-box", "wizard-pro-selector"],

  selectKitOptions: {
    autoFilterable: false,
    filterable: false,
    showFullTitle: true,
    headerComponent: "wizard-pro-selector/wizard-pro-selector-header",
    caretUpIcon: "caret-up",
    caretDownIcon: "caret-down",
  },

  modifyComponentForRow() {
    return "wizard-pro-selector/wizard-pro-selector-row";
  },
});
