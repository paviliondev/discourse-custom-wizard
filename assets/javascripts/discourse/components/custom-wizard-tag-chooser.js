import { makeArray } from "discourse/lib/helpers";
import TagChooser from "select-kit/components/tag-chooser";

export default TagChooser.extend({
  search(query) {
    const selectedTags = makeArray(this.tags).filter(Boolean);

    const data = {
      q: query,
      limit: this.siteSettings.max_tag_search_results,
      categoryId: this.categoryId,
    };

    if (selectedTags.length || this.blockedTags.length) {
      data.selected_tags = selectedTags
        .concat(this.blockedTags)
        .uniq()
        .slice(0, 100);
    }

    if (!this.everyTag) {
      data.filterForInput = true;
    }
    if (this.excludeSynonyms) {
      data.excludeSynonyms = true;
    }
    if (this.excludeHasSynonyms) {
      data.excludeHasSynonyms = true;
    }
    if (this.tagGroups) {
      let tagGroupsString = this.tagGroups.join(",");
      data.filterForInput = {
        name: "custom-wizard-tag-chooser",
        groups: tagGroupsString,
      };
    }
    return this.tagUtils.searchTags(
      "/tags/filter/search",
      data,
      this._transformJson
    );
  },
});
