import Component from "@ember/component";
import { loadOneboxes } from "discourse/lib/load-oneboxes";
import { later, schedule } from "@ember/runloop";
import {
  fetchUnseenHashtags,
  linkSeenHashtags,
} from "discourse/lib/link-hashtags";
import {
  fetchUnseenMentions,
  linkSeenMentions,
} from "discourse/lib/link-mentions";
import discourseDebounce from "discourse-common/lib/debounce";
import Composer from "discourse/models/composer";
import { resolveAllShortUrls } from "pretty-text/upload-short-url";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  init() {
    this._super();
    this.updatePreview();
  },

  updatePreview() {
    if (this.isDestroyed) {
      return;
    }

    schedule("afterRender", () => {
      if (this._state !== "inDOM" || !this.element) {
        return;
      }

      const $preview = $(this.element);

      if ($preview.length === 0) {
        return;
      }

      if (this.previewUpdated) {
        this.previewUpdated($preview);
      }
    });
  },

  previewUpdated($preview) {
    // Paint mentions
    const unseenMentions = linkSeenMentions($preview, this.siteSettings);
    if (unseenMentions.length) {
      discourseDebounce(
        this,
        this._renderUnseenMentions,
        $preview,
        unseenMentions,
        450
      );
    }

    this._warnMentionedGroups($preview);
    this._warnCannotSeeMention($preview);

    // Paint category and tag hashtags
    const unseenHashtags = linkSeenHashtags($preview);
    if (unseenHashtags.length > 0) {
      discourseDebounce(this, this._renderUnseenHashtags, $preview, 450);
    }

    // Paint oneboxes
    const paintFunc = () => {
      const post = this.get("composer.post");
      let refresh = false;

      //If we are editing a post, we'll refresh its contents once.
      if (post && !post.get("refreshedPost")) {
        refresh = true;
      }

      const paintedCount = loadOneboxes(
        $preview[0],
        ajax,
        this.get("composer.topic.id"),
        this.get("composer.category.id"),
        this.siteSettings.max_oneboxes_per_post,
        refresh
      );

      if (refresh && paintedCount > 0) {
        post.set("refreshedPost", true);
      }
    };

    discourseDebounce(this, paintFunc, 450);

    // Short upload urls need resolution
    resolveAllShortUrls(ajax, this.siteSettings, $preview[0]);
  },

  _warnMentionedGroups($preview) {
    schedule("afterRender", () => {
      let found = this.warnedGroupMentions || [];
      $preview.find(".mention-group.notify").each((idx, e) => {
        if (this._isInQuote(e)) {
          return;
        }

        const $e = $(e);
        let name = $e.data("name");
        if (found.indexOf(name) === -1) {
          this.groupsMentioned([
            {
              name: name,
              user_count: $e.data("mentionable-user-count"),
              max_mentions: $e.data("max-mentions"),
            },
          ]);
          found.push(name);
        }
      });

      this.set("warnedGroupMentions", found);
    });
  },

  _warnCannotSeeMention($preview) {
    const composerDraftKey = this.get("composer.draftKey");

    if (composerDraftKey === Composer.NEW_PRIVATE_MESSAGE_KEY) {
      return;
    }

    schedule("afterRender", () => {
      let found = this.warnedCannotSeeMentions || [];

      $preview.find(".mention.cannot-see").each((idx, e) => {
        const $e = $(e);
        let name = $e.data("name");

        if (found.indexOf(name) === -1) {
          // add a delay to allow for typing, so you don't open the warning right away
          // previously we would warn after @bob even if you were about to mention @bob2
          later(
            this,
            () => {
              if (
                $preview.find('.mention.cannot-see[data-name="' + name + '"]')
                  .length > 0
              ) {
                this.cannotSeeMention([{ name }]);
                found.push(name);
              }
            },
            2000
          );
        }
      });

      this.set("warnedCannotSeeMentions", found);
    });
  },

  _renderUnseenMentions($preview, unseen) {
    // 'Create a New Topic' scenario is not supported (per conversation with codinghorror)
    // https://meta.discourse.org/t/taking-another-1-7-release-task/51986/7
    fetchUnseenMentions(unseen, this.get("composer.topic.id")).then(() => {
      linkSeenMentions($preview, this.siteSettings);
      this._warnMentionedGroups($preview);
      this._warnCannotSeeMention($preview);
    });
  },

  _renderUnseenHashtags($preview) {
    const unseen = linkSeenHashtags($preview);
    if (unseen.length > 0) {
      fetchUnseenHashtags(unseen).then(() => {
        linkSeenHashtags($preview);
      });
    }
  },
});
