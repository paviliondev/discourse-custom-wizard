import Component from "@ember/component";
import discourseComputed, { observes } from 'discourse-common/utils/decorators';

export default Component.extend({
  @observes('value')
  updateValue(){
    this.set('field.value', this.value.join(','));
  },

  @discourseComputed('field.label')
  itemName(label){
    return label.replace(/(<([^>]+)>)/gi, "");
  }
});
