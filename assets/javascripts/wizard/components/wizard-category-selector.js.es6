import CategorySelector from 'select-kit/components/category-selector';
import { computed } from "@ember/object";
import { makeArray } from "discourse-common/lib/helpers";

export default CategorySelector.extend({
  content: computed("categories.[]", "blacklist.[]", "whitelist.[]", function() {
    return this._super().filter(category => {
      const whitelist = makeArray(this.whitelist);
      return !whitelist.length || whitelist.indexOf(category.id) > -1;
    });
  })
})