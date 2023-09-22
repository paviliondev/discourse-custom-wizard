import { action, set } from "@ember/object";
import { inject as service } from "@ember/service";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class WizardSubscriptionAuthorize extends Component {
  basePath = "/admin/plugins/subscription-client/suppliers";

  @service siteSettings;

  @tracked supplierId = null;
  @tracked authorized = false;
  @tracked unauthorizing = false;

  constructor() {
    super(...arguments);
    ajax("/admin/plugins/subscription-client/suppliers?final_landing_path%3D%2Fadmin%2Fwizards%2Fwizard").then((result) => {
      this.supplierId = result.suppliers[0].id;
      this.authorized = result.suppliers[0].authorized;
    })
  }

  @action
  authorize() {
    window.location.href = `${this.basePath}/authorize?supplier_id=${this.supplierId}`;
  }

  @action
  deauthorize() {
    this.unauthorizing = true;

    ajax(`${this.basePath}/authorize`, {
        type: "DELETE",
        data: {
          supplier_id: this.supplierId,
        },
      })
      .then((result) => {
        this.supplierId = result.suppliers[0].id;
        this.authorized = result.suppliers[0].authorized;
      })
      .finally(() => {
        this.unauthorizing = false;
      })
      .catch(popupAjaxError);
  };
}
