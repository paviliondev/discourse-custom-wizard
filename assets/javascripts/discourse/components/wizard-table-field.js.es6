import Component from "@ember/component";
import { action } from "@ember/object";
import { equal, notEmpty } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend({
  classNameBindings: ["value.type"],
  isText: equal("value.type", "text"),
  isComposer: equal("value.type", "composer"),
  isDate: equal("value.type", "date"),
  isTime: equal("value.type", "time"),
  isDateTime: equal("value.type", "date_time"),
  isNumber: equal("value.type", "number"),
  isCheckbox: equal("value.type", "checkbox"),
  isUrl: equal("value.type", "url"),
  isUpload: equal("value.type", "upload"),
  isDropdown: equal("value.type", "dropdown"),
  isTag: equal("value.type", "tag"),
  isCategory: equal("value.type", "category"),
  isGroup: equal("value.type", "group"),
  isUserSelector: equal("value.type", "user_selector"),
  isSubmittedAt: equal("field", "submitted_at"),
  isComposerPreview: equal("value.type", "composer_preview"),
  textState: "text-collapsed",
  toggleText: I18n.t("admin.wizard.expand_text"),

  @discourseComputed("value", "isUser")
  hasValue(value, isUser) {
    if (isUser) {
      return value;
    }
    return value && value.value;
  },

  @discourseComputed("field", "value.type")
  isUser(field, type) {
    return field === "username" || field === "user" || type === "user";
  },

  @discourseComputed("value.type")
  isLongtext(type) {
    return type === "textarea" || type === "long_text";
  },

  @discourseComputed("value")
  checkboxValue(value) {
    const isCheckbox = this.get("isCheckbox");
    if (isCheckbox) {
      if (value.value.includes("true")) {
        return true;
      } else if (value.value.includes("false")) {
        return false;
      }
    }
  },

  @action
  expandText() {
    const state = this.get("textState");

    if (state === "text-collapsed") {
      this.set("textState", "text-expanded");
      this.set("toggleText", I18n.t("admin.wizard.collapse_text"));
    } else if (state === "text-expanded") {
      this.set("textState", "text-collapsed");
      this.set("toggleText", I18n.t("admin.wizard.expand_text"));
    }
  },

  @discourseComputed("value")
  file(value) {
    const isUpload = this.get("isUpload");
    if (isUpload) {
      return value.value;
    }
  },

  @discourseComputed("value")
  submittedUsers(value) {
    const isUserSelector = this.get("isUserSelector");
    const users = [];

    if (isUserSelector) {
      const userData = value.value;
      const usernames = [];

      if (userData.indexOf(",")) {
        usernames.push(...userData.split(","));

        usernames.forEach((u) => {
          const user = {
            username: u,
            url: `/u/${u}`,
          };
          users.push(user);
        });
      }
    }
    return users;
  },

  @discourseComputed("isUser", "field", "value")
  username(isUser, field, value) {
    if (isUser) {
      return value.username;
    }
    if (field === "username") {
      return value.value;
    }
    return null;
  },

  showUsername: notEmpty("username"),

  @discourseComputed("username")
  userProfileUrl(username) {
    if (username) {
      return `/u/${username}`;
    }
    return "/";
  },

  @discourseComputed("value")
  categoryUrl(value) {
    const isCategory = this.get("isCategory");
    if (isCategory) {
      return `/c/${value.value}`;
    }
  },

  @discourseComputed("value")
  groupUrl(value) {
    const isGroup = this.get("isGroup");
    if (isGroup) {
      return `/g/${value.value}`;
    }
  },
});
