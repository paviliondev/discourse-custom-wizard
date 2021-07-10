import Component from "@ember/component";
import { loadOneboxes } from "discourse/lib/load-oneboxes";
import { schedule } from "@ember/runloop";
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
});
