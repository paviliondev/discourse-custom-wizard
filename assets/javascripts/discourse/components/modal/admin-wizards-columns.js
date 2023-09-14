import Component from "@glimmer/component";
import { action } from "@ember/object";

export default class AdminWizardsColumnComponent extends Component {
  title = I18n.t("admin.wizard.edit_columns");

  @action save() {
    this.args.closeModal();
  }

  @action resetToDefault() {
    this.args.model.reset();
  }
}
