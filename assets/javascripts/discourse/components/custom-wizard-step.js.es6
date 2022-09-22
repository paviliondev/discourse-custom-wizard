import discourseComputed, { observes } from "discourse-common/utils/decorators";
import Component from "@ember/component";
import I18n from "I18n";
import getUrl from "discourse-common/lib/get-url";
import { htmlSafe } from "@ember/template";
import { schedule } from "@ember/runloop";
import { cookAsync } from "discourse/lib/text";
import CustomWizard, {
  updateCachedWizard,
} from "discourse/plugins/discourse-custom-wizard/discourse/models/custom-wizard";
import { alias, not } from "@ember/object/computed";

const alreadyWarned = {};

export default Component.extend({
  classNameBindings: [":wizard-step", "step.id"],
  saving: null,

  init() {
    this._super(...arguments);
    this.set("stylingDropdown", {});
  },

  didReceiveAttrs() {
    this._super(...arguments);

    cookAsync(this.step.translatedTitle).then((cookedTitle) => {
      this.set("cookedTitle", cookedTitle);
    });
    cookAsync(this.step.translatedDescription).then((cookedDescription) => {
      this.set("cookedDescription", cookedDescription);
    });
  },

  didInsertElement() {
    this._super(...arguments);
    this.autoFocus();
  },

  @discourseComputed("step.index", "wizard.required")
  showQuitButton: (index, required) => index === 0 && !required,

  showNextButton: not("step.final"),
  showDoneButton: alias("step.final"),

  @discourseComputed(
    "step.index",
    "step.displayIndex",
    "wizard.totalSteps",
    "wizard.completed"
  )
  showFinishButton: (index, displayIndex, total, completed) => {
    return index !== 0 && displayIndex !== total && completed;
  },

  @discourseComputed("step.index")
  showBackButton: (index) => index > 0,

  @discourseComputed("step.banner")
  bannerImage(src) {
    if (!src) {
      return;
    }
    return getUrl(src);
  },

  @discourseComputed("step.id")
  bannerAndDescriptionClass(id) {
    return `wizard-banner-and-description wizard-banner-and-description-${id}`;
  },

  @discourseComputed("step.fields.[]")
  primaryButtonIndex(fields) {
    return fields.length + 1;
  },

  @discourseComputed("step.fields.[]")
  secondaryButtonIndex(fields) {
    return fields.length + 2;
  },

  @observes("step.id")
  _stepChanged() {
    this.set("saving", false);
    this.autoFocus();
  },

  @observes("step.message")
  _handleMessage: function () {
    const message = this.get("step.message");
    this.showMessage(message);
  },

  @discourseComputed("step.index", "wizard.totalSteps")
  barStyle(displayIndex, totalSteps) {
    let ratio = parseFloat(displayIndex) / parseFloat(totalSteps - 1);
    if (ratio < 0) {
      ratio = 0;
    }
    if (ratio > 1) {
      ratio = 1;
    }

    return htmlSafe(`width: ${ratio * 200}px`);
  },

  @discourseComputed("step.fields")
  includeSidebar(fields) {
    return !!fields.findBy("show_in_sidebar");
  },

  autoFocus() {
    schedule("afterRender", () => {
      const $invalid = $(
        ".wizard-field.invalid:nth-of-type(1) .wizard-focusable"
      );

      if ($invalid.length) {
        return $invalid.focus();
      }

      $(".wizard-focusable:first").focus();
    });
  },

  animateInvalidFields() {
    schedule("afterRender", () => {
      let $element = $(
        ".invalid input[type=text],.invalid textarea,.invalid input[type=checkbox],.invalid .select-kit"
      );

      if ($element.length) {
        $([document.documentElement, document.body]).animate(
          {
            scrollTop: $element.offset().top - 200,
          },
          400
        );
      }
    });
  },

  advance() {
    this.set("saving", true);
    this.get("step")
      .save()
      .then((response) => {
        updateCachedWizard(CustomWizard.build(response["wizard"]));

        if (response["final"]) {
          CustomWizard.finished(response);
        } else {
          this.goNext(response);
        }
      })
      .catch(() => this.animateInvalidFields())
      .finally(() => this.set("saving", false));
  },

  actions: {
    quit() {
      this.get("wizard").skip();
    },

    done() {
      this.send("nextStep");
    },

    showMessage(message) {
      this.sendAction(message);
    },

    stylingDropdownChanged(id, value) {
      this.set("stylingDropdown", { id, value });
    },

    exitEarly() {
      const step = this.step;
      step.validate();

      if (step.get("valid")) {
        this.set("saving", true);

        step
          .save()
          .then(() => this.send("quit"))
          .finally(() => this.set("saving", false));
      } else {
        this.autoFocus();
      }
    },

    backStep() {
      if (this.saving) {
        return;
      }

      this.goBack();
    },

    nextStep() {
      if (this.saving) {
        return;
      }

      const step = this.step;
      const result = step.validate();

      if (result.warnings.length) {
        const unwarned = result.warnings.filter((w) => !alreadyWarned[w]);
        if (unwarned.length) {
          unwarned.forEach((w) => (alreadyWarned[w] = true));
          return window.bootbox.confirm(
            unwarned.map((w) => I18n.t(`wizard.${w}`)).join("\n"),
            I18n.t("no_value"),
            I18n.t("yes_value"),
            (confirmed) => {
              if (confirmed) {
                this.advance();
              }
            }
          );
        }
      }

      if (step.get("valid")) {
        this.advance();
      } else {
        this.autoFocus();
      }
    },
  },
});
