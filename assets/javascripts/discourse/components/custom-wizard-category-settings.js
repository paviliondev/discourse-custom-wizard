import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import CustomWizardAdmin from "../models/custom-wizard-admin";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class CustomWizardCategorySettings extends Component {
  @tracked wizardList = [];
  @tracked wizardListVal =
    this.args?.category?.custom_fields?.create_topic_wizard;

  constructor() {
    super(...arguments);

    CustomWizardAdmin.all()
      .then((result) => {
        this.wizardList = result;
      })
      .catch(popupAjaxError);
  }

  @action
  changeWizard(wizard) {
    this.wizardListVal = wizard;
    this.args.category.custom_fields.create_topic_wizard = wizard;
  }
}
