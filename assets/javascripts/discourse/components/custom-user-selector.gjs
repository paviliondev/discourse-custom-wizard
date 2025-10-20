import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array } from "@ember/helper";
import { action } from "@ember/object";
import DMultiSelect from "discourse/components/d-multi-select";
import avatar from "discourse/helpers/avatar";
import icon from "discourse/helpers/d-icon";
import userSearch from "discourse/lib/user-search";

/**
 * Custom user selector component using DMultiSelect
 *
 * @component CustomUserSelector
 * @param {string} @usernames - Comma-separated string of selected usernames (read-only)
 * @param {boolean} @single - Whether to allow only single selection
 * @param {boolean} @allowAny - Whether to allow any input
 * @param {boolean} @disabled - Whether the component is disabled
 * @param {boolean} @includeGroups - Whether to include groups in search
 * @param {boolean} @includeMentionableGroups - Whether to include mentionable groups
 * @param {boolean} @includeMessageableGroups - Whether to include messageable groups
 * @param {boolean} @allowedUsers - Whether to restrict to allowed users only
 * @param {string} @topicId - Topic ID for context-aware search
 * @param {function} @onChangeCallback - Callback for selection changes
 */
export default class CustomUserSelector extends Component {
  @tracked selectedUsers = [];
  @tracked hasGroups = false;
  @tracked usernames = "";

  constructor(owner, args) {
    super(owner, args);
    this.parseInitialUsernames();
  }

  get includeMentionableGroups() {
    return this.args.includeMentionableGroups === "true";
  }

  get includeMessageableGroups() {
    return this.args.includeMessageableGroups === "true";
  }

  get includeGroups() {
    return this.args.includeGroups === "true";
  }

  get allowedUsers() {
    return this.args.allowedUsers === "true";
  }

  get single() {
    return this.args.single;
  }

  parseInitialUsernames() {
    if (!this.args.usernames) {
      this.selectedUsers = [];
      return;
    }

    const usernames = this.args.usernames.split(",").filter(Boolean);
    this.selectedUsers = usernames.map((username) => {
      const trimmedUsername = username.trim();
      // Create user object similar to what reverseTransform did in original
      return {
        username: trimmedUsername,
        name: trimmedUsername,
        id: trimmedUsername,
        isUser: true
      };
    });
  }

  @action
  async loadUsers(searchTerm) {
    const termRegex = /[^a-zA-Z0-9_\-\.@\+]/;
    const cleanTerm = searchTerm ? searchTerm.replace(termRegex, "") : "";

    // Get currently selected usernames for exclusion
    const excludedUsernames = this.single
      ? []
      : this.selectedUsers.map((u) => u.username);

    try {
      const results = await userSearch({
        term: cleanTerm,
        topicId: this.args.topicId,
        exclude: excludedUsernames,
        includeGroups: this.includeGroups,
        allowedUsers: this.allowedUsers,
        includeMentionableGroups: this.includeMentionableGroups,
        includeMessageableGroups: this.includeMessageableGroups
      });

      // Transform results to include both users and groups
      const transformedResults = [];

      if (results.users) {
        transformedResults.push(
          ...results.users.map((user) => ({
            ...user,
            isUser: true,
            id: user.username // Use username as ID for comparison
          }))
        );
      }

      if (results.groups) {
        transformedResults.push(
          ...results.groups.map((group) => ({
            ...group,
            isGroup: true,
            name: group.name, // Groups use name as username
            id: group.name // Use name as ID for comparison
          }))
        );
      }

      return transformedResults;
    } catch {
      return [];
    }
  }

  @action
  onSelectionChange(newSelection) {
    let selectedUsers = newSelection || [];

    if (this.single && selectedUsers.length > 1) {
      selectedUsers = [selectedUsers[selectedUsers.length - 1]];
    }

    this.selectedUsers = selectedUsers;
    this.hasGroups = this.selectedUsers.some((item) => item.isGroup);

    this.usernames = this.selectedUsers
      .map((item) => item.username || item.name)
      .join(",");

    if (this.args.onChangeCallback) {
      this.args.onChangeCallback(this.usernames);
    }
  }

  @action
  compareUsers(a, b) {
    return (a.username || a.name) === (b.username || b.name);
  }

  <template>
    <DMultiSelect
      @loadFn={{this.loadUsers}}
      @selection={{this.selectedUsers}}
      @onChange={{this.onSelectionChange}}
      @compareFn={{this.compareUsers}}
      @label={{this.placeholder}}
      class="custom-user-selector wizard-focusable"
      id="custom-member-selector"
      @placement="bottom-start"
      @allowedPlacements={{array "top-start" "bottom-start"}}
      @matchTriggerWidth={{true}}
      @matchTriggerMinWidth={{true}}
      disabled={{@disabled}}
    >
      <:selection as |user|>
        {{#if user.isGroup}}
          {{user.name}}
        {{else}}
          {{user.username}}
        {{/if}}
      </:selection>

      <:result as |user|>
        {{#if user.isGroup}}
          <div class="group-result">
            {{icon "users" class="group-icon"}}
            <span class="username">{{user.name}}</span>
          </div>
        {{else}}
          <div class="user-result">
            {{avatar user imageSize="tiny"}}
            <span class="username">{{user.username}}</span>
            {{#if user.name}}
              <span class="name">{{user.name}}</span>
            {{/if}}
          </div>
        {{/if}}
      </:result>

    </DMultiSelect>
  </template>
}
