import UserChooserComponent from "select-kit/components/user-chooser";
import I18n from "I18n";

export const WIZARD_USER = "wizard-user";

export default UserChooserComponent.extend({
  pluginApiIdentifiers: ["wizard-user-chooser"],
  classNames: ["user-chooser", "wizard-user-chooser"],
  classNameBindings: ["selectKit.options.fullWidthWrap:full-width-wrap"],
  valueProperty: "id",
  nameProperty: "name",

  modifyComponentForRow() {
    return "wizard-user-chooser/wizard-user-chooser-row";
  },

  modifyNoSelection() {
    return this.defaultItem(
      WIZARD_USER,
      I18n.t("admin.wizard.action.poster.wizard_user")
    );
  },

  selectKitOptions: {
    fullWidthWrap: false,
    autoWrap: false,
  },

  search() {
    const superPromise = this._super(...arguments);
    if (!superPromise) {
      return;
    }
    return superPromise.then((results) => {
      if (!results || results.length === 0) {
        return;
      }
      return results.map((item) => {
        const reconstructed = {};
        if (item.username) {
          reconstructed.id = item.username;
          if (item.username.includes("@")) {
            reconstructed.isEmail = true;
          } else {
            reconstructed.isUser = true;
            reconstructed.name = item.name;
            reconstructed.showUserStatus = this.showUserStatus;
          }
        } else if (item.name) {
          reconstructed.id = item.name;
          reconstructed.name = item.full_name;
          reconstructed.isGroup = true;
        }
        return { ...item, ...reconstructed };
      });
    });
  },
});
