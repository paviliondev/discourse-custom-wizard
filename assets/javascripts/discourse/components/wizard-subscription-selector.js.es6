import SingleSelectComponent from "select-kit/components/single-select";
import Subscription from "../mixins/subscription";
import wizardSchema from "discourse/plugins/discourse-custom-wizard/discourse/lib/wizard-schema";
import {
  subscriptionTypeSufficient,
  subscriptionTypes,
} from "discourse/plugins/discourse-custom-wizard/discourse/lib/wizard-subscription";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

const nameKey = function (feature, attribute, value) {
  if (feature === "action") {
    return `admin.wizard.action.${value}.label`;
  } else {
    return `admin.wizard.${feature}.${attribute}.${value}`;
  }
};

export default SingleSelectComponent.extend(Subscription, {
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

  requiredSubscriptionType(feature, attribute, value) {
    let attributes = this.subscriptionAttributes[feature];
    if (!attributes || !attributes[attribute]) {
      return null;
    }

    let requiredType = null;
    Object.keys(attributes[attribute]).some((subscriptionType) => {
      let values = attributes[attribute][subscriptionType];
      if (values[0] === "*" || values.includes(value)) {
        if (subscriptionTypes.includes(subscriptionType)) {
          requiredType = subscriptionType;
        }
        return true;
      }
      return false;
    });

    return requiredType;
  },

  @discourseComputed("feature", "attribute")
  content(feature, attribute) {
    return wizardSchema[feature][attribute].map((value) => {
      let requiredSubscriptionType = this.requiredSubscriptionType(
        feature,
        attribute,
        value
      );
      return {
        id: value,
        name: I18n.t(nameKey(feature, attribute, value)),
        subscriptionType: requiredSubscriptionType,
        disabled: !subscriptionTypeSufficient(
          this.subscriptionType,
          requiredSubscriptionType
        ),
      };
    }).sort(function(a, b) {
      if (a.subscriptionType && !b.subscriptionType) {
        return 1;
      }
      if (!a.subscriptionType && b.subscriptionType) {
        return -1;
      }
      if (a.subscriptionType == b.subscriptionType) {
        return a.subscriptionType ? a.subscriptionType.localeCompare(b.subscriptionType) : 0;
      } else {
        return a.subscriptionType === 'standard' ? -1 : 0;
      }
    });
  },

  modifyComponentForRow() {
    return "wizard-subscription-selector/wizard-subscription-selector-row";
  },
});
