import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { popupAjaxError } from "discourse/lib/ajax-error";
import CustomWizardAdmin from "../models/custom-wizard-admin";

export default class CustomWizardCategorySettings extends Component {
  @tracked wizardList = [];
  @tracked
  wizardListVal = this.args?.category?.custom_fields?.create_topic_wizard;

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
