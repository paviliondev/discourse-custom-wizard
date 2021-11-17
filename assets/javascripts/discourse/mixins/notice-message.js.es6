import Mixin from "@ember/object/mixin";
import { bind, scheduleOnce } from "@ember/runloop";
import { cookAsync } from "discourse/lib/text";
import { createPopper } from "@popperjs/core";

export default Mixin.create({
  showCookedMessage: false,

  didReceiveAttrs() {
    const message = this.notice.message;
    cookAsync(message).then((cooked) => {
      this.set("cookedMessage", cooked);
    });
  },

  createMessageModal() {
    let container = this.element.querySelector(".notice-message");
    let modal = this.element.querySelector(".cooked-notice-message");

    this._popper = createPopper(container, modal, {
      strategy: "absolute",
      placement: "bottom-start",
      modifiers: [
        {
          name: "preventOverflow",
        },
        {
          name: "offset",
          options: {
            offset: [0, 5],
          },
        },
      ],
    });
  },

  didInsertElement() {
    $(document).on("click", bind(this, this.documentClick));
  },

  willDestroyElement() {
    $(document).off("click", bind(this, this.documentClick));
  },

  documentClick(event) {
    if (this._state === "destroying") {
      return;
    }

    if (
      !event.target.closest(
        `[data-notice-id="${this.notice.id}"] .notice-message`
      )
    ) {
      this.set("showCookedMessage", false);
    }
  },

  actions: {
    toggleCookedMessage() {
      this.toggleProperty("showCookedMessage");

      if (this.showCookedMessage) {
        scheduleOnce("afterRender", this, this.createMessageModal);
      }
    },
  },
});
