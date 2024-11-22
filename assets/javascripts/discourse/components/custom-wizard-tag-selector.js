import { makeArray } from "discourse-common/lib/helpers";
import TagChooser from "select-kit/components/tag-chooser";

export default TagChooser.extend({
  _transformJson(context, json) {
    return this._super(context, json).filter((tag) => {
      const whitelist = makeArray(context.whitelist);
      return !whitelist.length || whitelist.indexOf(tag.id) > 1;
    });
  },
});
