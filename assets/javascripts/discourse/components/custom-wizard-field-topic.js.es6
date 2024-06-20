import { observes } from "discourse-common/utils/decorators";
import Topic from "discourse/models/topic";
import Component from "@ember/component";

export default Component.extend({
  topics: [],

  didInsertElement() {
    const value = this.field.value;

    if (value) {
      this.set("topics", value);
    }
    console.log(this.field)
  },

  actions: {
    setValue(topicIds, topics) {  
      if (topics.length) {
        this.set("field.value", topics);
      }
    },
  }
});
