import Component from "@ember/component";
import { computed } from "@ember/object";

export default Component.extend({
  classNameBindings: ["fieldClass"],

  @computed("includeGroups")
  get _includeGroups() {
    return this.get("includeGroups");
  },

  @computed("includeMentionableGroups")
  get _includeMentionableGroups() {
    return this.get("includeMentionableGroups");
  },

  @computed("includeMessageableGroups")
  get _includeMessageableGroups() {
    return this.get("includeMessageableGroups");
  },

  @computed("allowedUsers")
  get _allowedUsers() {
    return this.get("allowedUsers");
  },

  @computed("single")
  get _single() {
    return this.get("single");
  },

  @computed("topicId")
  get _topicId() {
    return this.get("topicId");
  },

  @computed("disabled")
  get _disabled() {
    return this.get("disabled");
  },

  get _onChangeCallback() {
    return this.get("onChangeCallback");
  },

  actions: {
    updateFieldValue(usernames) {
      this.set("field.value", usernames);

      // Call the original callback if it exists
      const originalCallback = this.get("onChangeCallback");
      if (originalCallback) {
        originalCallback();
      }
    },
  },
});
