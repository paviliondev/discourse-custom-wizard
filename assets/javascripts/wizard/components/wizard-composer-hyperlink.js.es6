import Component from "@ember/component";

export default Component.extend({
  actions: {
    addLink() {
      this.addLink(this.linkName, this.linkUrl);
    },
    hideBox() {
      this.hideBox();
    },
  },
});
