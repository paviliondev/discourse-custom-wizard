import { dasherize } from "@ember/string";
import discourseComputed from "discourse-common/utils/decorators";

export default {
  name: "custom-wizard-field",
  initialize() {
    if (window.location.pathname.indexOf("/w/") < 0) {
      return;
    }

    const FieldComponent = requirejs("wizard/components/wizard-field").default;
    const FieldModel = requirejs("wizard/models/wizard-field").default;
    const { cook } = requirejs(
      "discourse/plugins/discourse-custom-wizard/wizard/lib/text-lite"
    );
    const DEditor = requirejs("discourse/components/d-editor").default;
    const { clipboardHelpers } = requirejs("discourse/lib/utilities");
    const toMarkdown = requirejs("discourse/lib/to-markdown").default;
    const { translatedText } = requirejs(
      "discourse/plugins/discourse-custom-wizard/wizard/lib/wizard-i18n"
    );

    FieldComponent.reopen({
      classNameBindings: ["field.id"],

      @discourseComputed("field.translatedDescription")
      cookedDescription(description) {
        return cook(description);
      },

      @discourseComputed("field.type")
      textType(fieldType) {
        return ["text", "textarea"].includes(fieldType);
      },

      inputComponentName: function () {
        const type = this.get("field.type");
        const id = this.get("field.id");
        if (["text_only"].includes(type)) {
          return false;
        }
        return dasherize(type === "component" ? id : `wizard-field-${type}`);
      }.property("field.type", "field.id"),
    });

    const StandardFieldValidation = [
      "text",
      "number",
      "textarea",
      "dropdown",
      "tag",
      "image",
      "user_selector",
      "text_only",
      "composer",
      "category",
      "group",
      "date",
      "time",
      "date_time",
    ];

    FieldModel.reopen({
      @discourseComputed("wizardId", "stepId", "id")
      i18nKey(wizardId, stepId, id) {
        return `${wizardId}.${stepId}.${id}`;
      },

      @discourseComputed("i18nKey", "label")
      translatedLabel(i18nKey, label) {
        return translatedText(`${i18nKey}.label`, label);
      },

      @discourseComputed("i18nKey", "placeholder")
      translatedPlaceholder(i18nKey, placeholder) {
        return translatedText(`${i18nKey}.placeholder`, placeholder);
      },

      @discourseComputed("i18nKey", "description")
      translatedDescription(i18nKey, description) {
        return translatedText(`${i18nKey}.description`, description);
      },

      check() {
        if (this.customCheck) {
          return this.customCheck();
        }

        let valid = this.valid;

        if (!this.required) {
          this.setValid(true);
          return true;
        }

        const val = this.get("value");
        const type = this.get("type");

        if (type === "checkbox") {
          valid = val;
        } else if (type === "upload") {
          valid = val && val.id > 0;
        } else if (StandardFieldValidation.indexOf(type) > -1) {
          valid = val && val.toString().length > 0;
        } else if (type === "url") {
          valid = true;
        }

        this.setValid(valid);

        return valid;
      },
    });

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

      _wizardInsertText(args = {}) {
        if (args.fieldId === this.fieldId) {
          this._insertText(args.text, args.options);
        }
      },

      _wizardReplaceText(args = {}) {
        if (args.fieldId === this.fieldId) {
          this._replaceText(args.oldVal, args.newVal, (args.opts = {}));
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

        const { pre, lineVal } = this._getSelected(null, { lineVal: true });
        const isInlinePasting = pre.match(/[^\n]$/);
        const isCodeBlock = isInside(pre, /(^|\n)```/g);

        if (
          plainText &&
          this.siteSettings.enable_rich_text_paste &&
          !isInlinePasting &&
          !isCodeBlock
        ) {
          plainText = plainText.trim().replace(/\r/g, "");
          const table = this._extractTable(plainText);
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
  },
};
