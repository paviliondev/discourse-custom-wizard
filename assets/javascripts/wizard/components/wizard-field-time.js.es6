import Component from "@ember/component";
import { observes } from 'discourse-common/utils/decorators';

export default Component.extend({
  @observes('time')
  setValue() {
    this.set('field.value', this.time.format(this.field.format));
  },
  
  actions: {
    onChange(value) {
      this.set('time',
        moment({
          hours: value.hours,
          minutes: value.minutes
        })
      )
    }
  }
});