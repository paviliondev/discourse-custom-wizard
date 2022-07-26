import Site from "discourse/models/site";
import { getOwner } from "discourse-common/lib/get-owner";

export default Site.reopenClass({
  // There is no site data actually loaded by the CW yet. This placeholder is
  // needed by imported classes
  createCurrent() {
    const store = getOwner(this).lookup("service:store");
    return store.createRecord("site", {});
  },
});
