import TagChooser from 'select-kit/components/tag-chooser';
import { makeArray } from "discourse-common/lib/helpers";

export default TagChooser.extend({
  _transformJson(context, json) {
    return this._super(context, json).filter((tag) => {
      const whitelist = makeArray(context.whitelist);
      return !whitelist.length || whitelist.indexOf(tag.id) > 1;
    });
  }
})