import SingleSelectComponent from "select-kit/components/single-select";

export default SingleSelectComponent.extend({
  classNames: ["combo-box", "wizard-subscription-selector"],

  selectKitOptions: {
    autoFilterable: false,
    filterable: false,
    showFullTitle: true,
    headerComponent:
      "wizard-subscription-selector/wizard-subscription-selector-header",
    caretUpIcon: "caret-up",
    caretDownIcon: "caret-down",
  },

  modifyComponentForRow() {
    return "wizard-subscription-selector/wizard-subscription-selector-row";
  },
});
