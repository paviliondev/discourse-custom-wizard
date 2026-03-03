import { makeArray } from "discourse/lib/helpers";
import TagChooser from "discourse/select-kit/components/tag-chooser";

export default TagChooser.extend({
  _selectedTagPayload(selectedTags, blockedTags) {
    const selectedTagIds = [];
    const selectedTagNames = [];

    selectedTags
      .concat(blockedTags)
      .uniq()
      .slice(0, 100)
      .forEach((tag) => {
        if (typeof tag === "string") {
          selectedTagNames.push(tag);
        } else if (tag?.id !== null && tag?.id !== undefined) {
          selectedTagIds.push(tag.id);
        }
      });

    return { selectedTagIds, selectedTagNames };
  },

  search(query) {
    const selectedTags = makeArray(this.tags).filter(Boolean);

    const data = {
      q: query,
      limit: this.siteSettings.max_tag_search_results,
      categoryId: this.categoryId,
    };

    if (selectedTags.length || this.blockedTags.length) {
      const { selectedTagIds, selectedTagNames } = this._selectedTagPayload(
        selectedTags,
        this.blockedTags
      );

      if (selectedTagIds.length) {
        data.selected_tag_ids = selectedTagIds;
      }

      if (selectedTagNames.length) {
        data.selected_tags = selectedTagNames;
      }
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
