import { service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import SingleSelectComponent from "select-kit/components/single-select";
import { filterValues } from "discourse/plugins/discourse-custom-wizard/discourse/lib/wizard-schema";

const nameKey = function (feature, attribute, value) {
  if (feature === "action") {
    return `admin.wizard.action.${value}.label`;
  } else {
    return `admin.wizard.${feature}.${attribute}.${value}`;
  }
};

export default SingleSelectComponent.extend({
  classNames: ["combo-box", "wizard-subscription-selector"],
  subscription: service(),

  selectKitOptions: {
    autoFilterable: false,
    filterable: false,
    showFullTitle: true,
    headerComponent:
      "wizard-subscription-selector/wizard-subscription-selector-header",
    caretUpIcon: "caret-up",
    caretDownIcon: "caret-down",
  },

  allowedSubscriptionTypes(feature, attribute, value) {
    let attributes = this.subscription.subscriptionAttributes[feature];
    if (!attributes || !attributes[attribute]) {
      return ["none"];
    }
    let allowedTypes = [];
    Object.keys(attributes[attribute]).forEach((subscriptionType) => {
      let values = attributes[attribute][subscriptionType];
      if (values[0] === "*" || values.includes(value)) {
        allowedTypes.push(subscriptionType);
      }
    });
    return allowedTypes;
  },

  @discourseComputed("feature", "attribute", "wizard.allowGuests")
  content(feature, attribute) {
    return filterValues(this.wizard, feature, attribute)
      .map((value) => {
        let allowedSubscriptionTypes = this.allowedSubscriptionTypes(
          feature,
          attribute,
          value
        );

        let subscriptionRequired = false;

        let attrs = {
          id: value,
          name: I18n.t(nameKey(feature, attribute, value)),
          subscriptionRequired,
        };
        if (subscriptionRequired) {
          let subscribed = allowedSubscriptionTypes.includes(
            this.subscription.subscriptionType
          );
          let selectorKey = subscribed ? "subscribed" : "not_subscribed";
          let selectorLabel = `admin.wizard.subscription.${selectorKey}.selector`;

          attrs.disabled = !subscribed;
          attrs.selectorLabel = selectorLabel;
        }

        return attrs;
      })
      .sort(function (a, b) {
        if (a.subscriptionType && !b.subscriptionType) {
          return 1;
        }
        if (!a.subscriptionType && b.subscriptionType) {
          return -1;
        }
        if (a.subscriptionType === b.subscriptionType) {
          return a.subscriptionType
            ? a.subscriptionType.localeCompare(b.subscriptionType)
            : 0;
        } else {
          return a.subscriptionType === "standard" ? -1 : 0;
        }
      });
  },

  modifyComponentForRow() {
    return "wizard-subscription-selector/wizard-subscription-selector-row";
  },
});
