import { default as computed, observes } from 'ember-addons/ember-computed-decorators';
import { renderAvatar } from 'discourse/helpers/user-avatar';
import userSearch from '../lib/user-search';

const template = function(params) {
  const options = params.options;
  let html = "<div class='autocomplete'>";

  if (options.users) {
    html += "<ul>";
    options.users.forEach((u) => {
      html += `<li><a href title="${u.name}">`;
      html += renderAvatar(u, { imageSize: 'tiny' });
      html += `<span class='username'>${u.username}</span>`;
      if (u.name) {
        html += `<span class='name'>${u.name}</span>`;
      }
      html += `</a></li>`;
    });
    html += "</ul>";
  };

  html += "</div>";

  return new Handlebars.SafeString(html).string;
};

export default Ember.TextField.extend({
  attributeBindings: ['autofocus', 'maxLength'],
  autocorrect: false,
  autocapitalize: false,
  name: 'user-selector',
  id: "custom-member-selector",

  @computed("placeholderKey")
  placeholder(placeholderKey) {
    return placeholderKey ? I18n.t(placeholderKey) : "";
  },

  @observes('usernames')
  _update() {
    if (this.get('canReceiveUpdates') === 'true')
      this.didInsertElement({updateData: true});
  },

  didInsertElement(opts) {
    this._super();
    var self = this,
        selected = [],
        groups = [],
        currentUser = this.currentUser,
        includeMentionableGroups = this.get('includeMentionableGroups') === 'true',
        includeMessageableGroups = this.get('includeMessageableGroups') === 'true',
        includeGroups = this.get('includeGroups') === 'true',
        allowedUsers = this.get('allowedUsers') === 'true';

    function excludedUsernames() {
      // hack works around some issues with allowAny eventing
      const usernames = self.get('single') ? [] : selected;

      if (currentUser && self.get('excludeCurrentUser')) {
        return usernames.concat([currentUser.get('username')]);
      }
      return usernames;
    }

    this.$().val(this.get('usernames')).autocomplete({
      template,
      disabled: this.get('disabled'),
      single: this.get('single'),
      allowAny: this.get('allowAny'),
      updateData: (opts && opts.updateData) ? opts.updateData : false,

      dataSource(term) {
        const termRegex = /[^a-zA-Z0-9_\-\.@\+]/;

        var results = userSearch({
          term: term.replace(termRegex, ''),
          topicId: self.get('topicId'),
          exclude: excludedUsernames(),
          includeGroups,
          allowedUsers,
          includeMentionableGroups,
          includeMessageableGroups
        });

        return results;
      },

      transformComplete(v) {
        if (v.username || v.name) {
          if (!v.username) { groups.push(v.name); }
          return v.username || v.name;
        } else {
          var excludes = excludedUsernames();
          return v.usernames.filter(function(item){
            return excludes.indexOf(item) === -1;
          });
        }
      },

      onChangeItems(items) {
        var hasGroups = false;
        items = items.map(function(i) {
          if (groups.indexOf(i) > -1) { hasGroups = true; }
          return i.username ? i.username : i;
        });
        self.set('usernames', items.join(","));
        self.set('hasGroups', hasGroups);

        selected = items;
        if (self.get('onChangeCallback')) self.sendAction('onChangeCallback');
      },

      reverseTransform(i) {
        return { username: i };
      }

    });
  },

  willDestroyElement() {
    this._super();
    this.$().autocomplete('destroy');
  },

  // THIS IS A HUGE HACK TO SUPPORT CLEARING THE INPUT
  @observes('usernames')
  _clearInput: function() {
    if (arguments.length > 1) {
      if (Em.isEmpty(this.get("usernames"))) {
        this.$().parent().find("a").click();
      }
    }
  }

});
