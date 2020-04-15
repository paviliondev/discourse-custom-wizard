import ComboBox from 'select-kit/components/combo-box';
import { computed } from "@ember/object";
import { makeArray } from "discourse-common/lib/helpers";

export default ComboBox.extend({  
  content: computed("groups.[]", "field.content.[]", function() {
    const whitelist = makeArray(this.field.content);
    return this.groups.filter(group => {
      return !whitelist.length || whitelist.indexOf(group.id) > -1;
    }).map(g => {
      return {
        id: g.id,
        name: g.full_name ? g.full_name : g.name
      }
    });
  })
})