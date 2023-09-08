// import { geoLocationSearch, providerDetails } from "../lib/location-utilities";
//import { ajax } from "discourse/lib/ajax";
import { action, set } from "@ember/object";
// import { equal } from "@ember/object/computed";
// import { A } from "@ember/array";
import { inject as service } from "@ember/service";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
// import I18n from "I18n";

export default class WizardSubscriptionAuthorize extends Component {
  @service siteSettings;
  @tracked supplierId = null;
  @tracked authorized = false;

  constructor() {
    super(...arguments);
    ajax("/admin/plugins/subscription-client/suppliers").then((result) => {
      this.supplierId = result.suppliers[0].id;
      this.authorized = result.suppliers[0].authorized;
    })
  }

  @action
  authorize() {
    window.location.href = `/admin/plugins/subscription-client/suppliers/authorize?supplier_id=${this.supplierId}`;
  }
}
