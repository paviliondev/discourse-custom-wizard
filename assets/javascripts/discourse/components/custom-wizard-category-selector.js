import { computed } from "@ember/object";
import { makeArray } from "discourse-common/lib/helpers";
import CategorySelector from "select-kit/components/category-selector";

export default CategorySelector.extend({
  classNames: ["category-selector", "wizard-category-selector"],
  content: computed(
    "categoryIds.[]",
    "blacklist.[]",
    "whitelist.[]",
    function () {
      return this._super().filter((category) => {
        const whitelist = makeArray(this.whitelist);
        return !whitelist.length || whitelist.indexOf(category.id) > -1;
      });
    }
  ),
});
