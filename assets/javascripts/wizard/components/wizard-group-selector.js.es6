import ComboBox from 'select-kit/components/combo-box';
import { computed } from "@ember/object";
import { makeArray } from "discourse-common/lib/helpers";

export default ComboBox.extend({
  content: computed("groups.[]", "whitelist.[]", function() {
    const whitelist = makeArray(this.whitelist);
    return this.groups.filter(group => {
      return !whitelist.length || whitelist.indexOf(group.id) > -1;
    });
  })
})