import Site from "discourse/models/site";

export default Site.reopenClass({
  // There is no site data actually loaded by the CW yet. This placeholder is
  // needed by imported classes
  createCurrent() {
    const store = Discourse.__container__.lookup("service:store");
    return store.createRecord("site", {});
  },
})