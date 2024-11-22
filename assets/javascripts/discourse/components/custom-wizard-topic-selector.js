import { isEmpty } from "@ember/utils";
import { searchForTerm } from "discourse/lib/search";
import { makeArray } from "discourse-common/lib/helpers";
import MultiSelectComponent from "select-kit/components/multi-select";

export default MultiSelectComponent.extend({
  classNames: ["topic-selector", "wizard-topic-selector"],
  topics: null,
  value: [],
  content: [],
  nameProperty: "fancy_title",
  labelProperty: "title",
  titleProperty: "title",

  selectKitOptions: {
    clearable: true,
    filterable: true,
    filterPlaceholder: "choose_topic.title.placeholder",
    allowAny: false,
  },

  didReceiveAttrs() {
    if (this.topics && !this.selectKit.hasSelection) {
      const values = makeArray(this.topics.map((t) => t.id));
      const content = makeArray(this.topics);
      this.selectKit.change(values, content);
    }
    this._super(...arguments);
  },

  modifyComponentForRow() {
    return "topic-row";
  },

  search(filter) {
    if (isEmpty(filter)) {
      return [];
    }

    const searchParams = {};
    searchParams.typeFilter = "topic";
    searchParams.restrictToArchetype = "regular";
    searchParams.searchForId = true;

    if (this.category) {
      searchParams.searchContext = {
        type: "category",
        id: this.category,
      };
    }

    return searchForTerm(filter, searchParams).then((results) => {
      if (results?.posts?.length > 0) {
        return results.posts.mapBy("topic");
      }
    });
  },

  actions: {
    onChange(value, items) {
      const content = items.map((t) => {
        return {
          id: t.id,
          title: t.title,
          fancy_title: t.fancy_title,
          url: t.url,
        };
      });
      this.setProperties({ value, content });
      this.onChange(value, content);
    },
  },
});
