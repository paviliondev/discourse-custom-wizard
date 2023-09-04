// import { geoLocationSearch, providerDetails } from "../lib/location-utilities";
//import { ajax } from "discourse/lib/ajax";
import { action, set } from "@ember/object";
// import { equal } from "@ember/object/computed";
// import { A } from "@ember/array";
import { inject as service } from "@ember/service";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
// import I18n from "I18n";

export default class WizardSubscriptionAuthorize extends Component {
  @service siteSettings;
  @tracked supplierId = 1;

  constructor() {
    super(...arguments);

  }

  @action
  authorize() {
    window.location.href = `${basePath}/authorize?supplier_id=${this.supplierId}`;
  }
}
