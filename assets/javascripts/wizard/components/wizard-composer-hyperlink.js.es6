import Component from "@ember/component";

export default Component.extend({
  classNames: ['wizard-composer-hyperlink'],
  
  actions: {
    addLink() {
      this.addLink(this.linkName, this.linkUrl);
    },
    
    hideBox() {
      this.hideBox();
    }
  },
});
