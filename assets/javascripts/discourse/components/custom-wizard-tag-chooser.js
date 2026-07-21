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
    const blockedTags = this._normalizedBlockedTags;

    const data = {
      q: query,
      limit: this.siteSettings.max_tag_search_results,
    };

    if (selectedTags.length || blockedTags.length) {
      const { selectedTagIds, selectedTagNames } = this._selectedTagPayload(
        selectedTags,
        blockedTags
      );

      if (selectedTagIds.length) {
        data.selected_tag_ids = selectedTagIds;
      }

      if (selectedTagNames.length) {
        data.selected_tags = selectedTagNames;
      }
    }

    if (this.tagGroups?.length) {
      data.tag_groups = this.tagGroups.join(",");
    }

    const contentTags = makeArray(this.whitelist)
      .map((tag) => (typeof tag === "string" ? tag : tag?.name))
      .filter(Boolean);
    if (contentTags.length) {
      data.content = contentTags;
    }

    return this.tagUtils.searchTags(
      "/custom-wizard/tags/search",
      data,
      this._transformJson
    );
  },
});
