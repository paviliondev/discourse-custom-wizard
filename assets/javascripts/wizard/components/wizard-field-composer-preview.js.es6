import Component from "@ember/component";
import { loadOneboxes } from "discourse/lib/load-oneboxes";
import { schedule } from "@ember/runloop";
import {
  fetchUnseenHashtags,
  linkSeenHashtags,
} from "discourse/lib/link-hashtags";
import {
  fetchUnseenMentions,
  linkSeenMentions,
} from "discourse/lib/link-mentions";
import discourseDebounce from "discourse-common/lib/debounce";
import { resolveAllShortUrls } from "pretty-text/upload-short-url";
import { ajax } from "discourse/lib/ajax";
import { on } from "discourse-common/utils/decorators";

export default Component.extend({
  @on("init")
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

      this.previewUpdated($preview);
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

    // Paint category and tag hashtags
    const unseenHashtags = linkSeenHashtags($preview);
    if (unseenHashtags.length > 0) {
      discourseDebounce(this, this._renderUnseenHashtags, $preview, 450);
    }

    // Paint oneboxes
    const paintFunc = () => {
      loadOneboxes(
        $preview[0],
        ajax,
        null,
        null,
        this.siteSettings.max_oneboxes_per_post,
        true // refresh on every load
      );
    };

    discourseDebounce(this, paintFunc, 450);

    // Short upload urls need resolution
    resolveAllShortUrls(ajax, this.siteSettings, $preview[0]);
  },

  _renderUnseenMentions($preview, unseen) {
    // 'Create a New Topic' scenario is not supported (per conversation with codinghorror)
    // https://meta.discourse.org/t/taking-another-1-7-release-task/51986/7
    fetchUnseenMentions(unseen, this.get("composer.topic.id")).then(() => {
      linkSeenMentions($preview, this.siteSettings);
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
