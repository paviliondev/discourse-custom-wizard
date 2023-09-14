import Component from "@glimmer/component";
import { action } from "@ember/object";
import I18n from "I18n";

export default class AdminWizardsColumnComponent extends Component {
  title = I18n.t("admin.wizard.edit_columns");

  @action save() {
    this.args.closeModal();
  }

  @action resetToDefault() {
    this.args.model.reset();
  }
}
