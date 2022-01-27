import TagChooser from "select-kit/components/tag-chooser";

export default TagChooser.extend({
  searchTags(url, data, callback) {
    if (this.tagGroups) {
      let tagGroupsString = this.tagGroups.join(",");
      data.tagGroups = tagGroupsString;
    }

    return this._super(url, data, callback);
  },
});
