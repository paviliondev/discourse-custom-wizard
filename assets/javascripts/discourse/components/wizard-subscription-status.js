import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class WizardSubscriptionStatus extends Component {
  @service siteSettings;
  @service subscription;
  @tracked supplierId = null;
  @tracked authorized = false;
  @tracked unauthorizing = false;
  basePath = "/admin/plugins/subscription-client/suppliers";

  constructor() {
    super(...arguments);
    ajax(`${this.basePath}`)
      .then((result) => {
        this.supplierId = result.suppliers[0].id;
        this.authorized = result.suppliers[0].authorized;
      })
      .finally(() => {
        this.subscription.retrieveSubscriptionStatus();
      });
  }

  @action
  authorize() {
    window.location.href = `${this.basePath}/authorize?supplier_id=${this.supplierId}&final_landing_path=/admin/wizards/wizard`;
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
        this.supplierId = result.supplier.id;
        this.authorized = !(result.supplier.authorized_at === null);
      })
      .finally(() => {
        this.unauthorizing = false;
        this.subscription.retrieveSubscriptionStatus();
      })
      .catch(popupAjaxError);
  }
}
