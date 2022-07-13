export default {
  run(app, container) {
    const getToken = requirejs(
      "discourse/plugins/discourse-custom-wizard/wizard/lib/ajax"
    ).getToken;
    const isTesting = requirejs("discourse-common/config/environment")
      .isTesting;

    if (!isTesting()) {
      // Add a CSRF token to all AJAX requests
      let token = getToken();
      const session = container.lookup("session:main");
      session.set("csrfToken", token);
      let callbacks = $.Callbacks();
      $.ajaxPrefilter(callbacks.fire);

      callbacks.add(function (options, originalOptions, xhr) {
        if (!options.crossDomain) {
          xhr.setRequestHeader("X-CSRF-Token", session.get("csrfToken"));
        }
      });
    }

    const DEditor = requirejs("discourse/components/d-editor").default;
    const { clipboardHelpers } = requirejs("discourse/lib/utilities");
    const toMarkdown = requirejs("discourse/lib/to-markdown").default;
    const discourseComputed = requirejs("discourse-common/utils/decorators")
      .default;
    const WizardI18n = requirejs(
      "discourse/plugins/discourse-custom-wizard/wizard/lib/wizard-i18n"
    ).default;
    const isInside = (text, regex) => {
      const matches = text.match(regex);
      return matches && matches.length % 2;
    };

    DEditor.reopen({
      isComposer: true,

      didInsertElement() {
        this._super();
        if (this.wizardComposerEvents) {
          this.appEvents.on(
            "wizard-editor:insert-text",
            this,
            "_wizardInsertText"
          );
          this.appEvents.on(
            "wizard-editor:replace-text",
            this,
            "_wizardReplaceText"
          );
        }
      },

      @discourseComputed("placeholder", "placeholderOverride")
      placeholderTranslated(placeholder, placeholderOverride) {
        if (placeholderOverride) {
          return placeholderOverride;
        }
        if (placeholder) {
          return WizardI18n(placeholder);
        }
        return null;
      },

      _wizardInsertText(args = {}) {
        if (args.fieldId === this.fieldId) {
          this.insertText(args.text, args.options);
        }
      },

      _wizardReplaceText(args = {}) {
        if (args.fieldId === this.fieldId) {
          this.replaceText(args.oldVal, args.newVal, (args.opts = {}));
        }
      },

      paste(e) {
        if (!$(".d-editor-input").is(":focus")) {
          return;
        }

        const isComposer = this.isComposer;
        let { clipboard, canPasteHtml, canUpload } = clipboardHelpers(e, {
          siteSettings: this.siteSettings,
          canUpload: isComposer,
        });

        let plainText = clipboard.getData("text/plain");
        let html = clipboard.getData("text/html");
        let handled = false;

        const { pre, lineVal } = this.getSelected(null, { lineVal: true });
        const isInlinePasting = pre.match(/[^\n]$/);
        const isCodeBlock = isInside(pre, /(^|\n)```/g);

        if (
          plainText &&
          this.siteSettings.enable_rich_text_paste &&
          !isInlinePasting &&
          !isCodeBlock
        ) {
          plainText = plainText.trim().replace(/\r/g, "");
          const table = this.extractTable(plainText);
          if (table) {
            this.appEvents.trigger("wizard-editor:insert-text", {
              fieldId: this.fieldId,
              text: table,
            });
            handled = true;
          }
        }

        if (canPasteHtml && plainText) {
          if (isInlinePasting) {
            canPasteHtml = !(
              lineVal.match(/^```/) ||
              isInside(pre, /`/g) ||
              lineVal.match(/^    /)
            );
          } else {
            canPasteHtml = !isCodeBlock;
          }
        }

        if (canPasteHtml && !handled) {
          let markdown = toMarkdown(html);

          if (!plainText || plainText.length < markdown.length) {
            if (isInlinePasting) {
              markdown = markdown.replace(/^#+/, "").trim();
              markdown = pre.match(/\S$/) ? ` ${markdown}` : markdown;
            }

            this.appEvents.trigger("wizard-editor:insert-text", {
              fieldId: this.fieldId,
              text: markdown,
            });
            handled = true;
          }
        }

        if (handled || (canUpload && !plainText)) {
          e.preventDefault();
        }
      },
    });

    // IE11 Polyfill - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/entries#Polyfill
    if (!Object.entries) {
      Object.entries = function (obj) {
        let ownProps = Object.keys(obj),
          i = ownProps.length,
          resArray = new Array(i); // preallocate the Array
        while (i--) {
          resArray[i] = [ownProps[i], obj[ownProps[i]]];
        }

        return resArray;
      };
    }
  },
};
