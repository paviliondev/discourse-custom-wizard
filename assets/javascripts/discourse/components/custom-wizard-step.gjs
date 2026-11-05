/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { on } from "@ember/modifier";
import { action, computed } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { schedule } from "@ember/runloop";
import { trustHTML } from "@ember/template";
import { classNameBindings } from "@ember-decorators/component";
import getUrl from "discourse/lib/get-url";
import discourseLater from "discourse/lib/later";
import { cook } from "discourse/lib/text";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dLoadingSpinner from "discourse/ui-kit/helpers/d-loading-spinner";
import { i18n } from "discourse-i18n";
import CustomWizard, {
  updateCachedWizard,
} from "discourse/plugins/discourse-custom-wizard/discourse/models/custom-wizard";
import { wizardComposerEdtiorEventPrefix } from "./custom-wizard-composer-editor";
import CustomWizardField from "./custom-wizard-field";
import CustomWizardStepForm from "./custom-wizard-step-form";

const uploadStartedEventKeys = ["upload-started"];
const uploadEndedEventKeys = [
  "upload-success",
  "upload-error",
  "upload-cancelled",
  "uploads-cancelled",
  "uploads-aborted",
  "all-uploads-complete",
];

@classNameBindings(":wizard-step", "step.id")
export default class CustomWizardStep extends Component {
  saving = null;

  init() {
    super.init(...arguments);
    this.set("stylingDropdown", {});
  }

  didReceiveAttrs() {
    super.didReceiveAttrs(...arguments);

    if (this._receivedAttrs) {
      if (this._stepId !== this.step.id) {
        this.set("saving", false);
        this.autoFocus();
      }
    }

    this._stepId = this.step.id;
    this._receivedAttrs = true;

    cook(this.step.translatedTitle).then((cookedTitle) => {
      this.set("cookedTitle", cookedTitle);
    });
    cook(this.step.translatedDescription).then((cookedDescription) => {
      this.set("cookedDescription", cookedDescription);
    });

    uploadStartedEventKeys.forEach((key) => {
      this.appEvents.on(`${wizardComposerEdtiorEventPrefix}:${key}`, () => {
        this.set("uploading", true);
      });
    });
    uploadEndedEventKeys.forEach((key) => {
      this.appEvents.on(`${wizardComposerEdtiorEventPrefix}:${key}`, () => {
        this.set("uploading", false);
      });
    });
  }

  didInsertElement() {
    super.didInsertElement(...arguments);
    this.autoFocus();
  }

  @computed("step.index", "wizard.required")
  get showQuitButton() {
    return this.step.index === 0 && !this.wizard.required;
  }

  @computed("step.final")
  get showNextButton() {
    return !this.step.final;
  }

  @computed("step.final")
  get showDoneButton() {
    return this.step.final;
  }

  @computed("saving", "uploading")
  get btnsDisabled() {
    return this.saving || this.uploading;
  }

  @computed(
    "step.index",
    "step.displayIndex",
    "wizard.totalSteps",
    "wizard.completed"
  )
  get showFinishButton() {
    return (
      this.step.index !== 0 &&
      this.step.displayIndex !== this.wizard.totalSteps &&
      this.wizard.completed
    );
  }

  @computed("step.index")
  get showBackButton() {
    return this.step.index > 0;
  }

  @computed("step.banner")
  get bannerImage() {
    if (!this.step.banner) {
      return;
    }
    return getUrl(this.step.banner);
  }

  @computed("step.id")
  get bannerAndDescriptionClass() {
    return `wizard-banner-and-description wizard-banner-and-description-${this.step.id}`;
  }

  @computed("step.fields.[]")
  get primaryButtonIndex() {
    return this.step.fields.length + 1;
  }

  @computed("step.fields.[]")
  get secondaryButtonIndex() {
    return this.step.fields.length + 2;
  }

  @computed("step.index", "wizard.totalSteps")
  get barStyle() {
    let ratio =
      parseFloat(this.step.index) / parseFloat(this.wizard.totalSteps - 1);
    if (ratio < 0) {
      ratio = 0;
    }
    if (ratio > 1) {
      ratio = 1;
    }

    return trustHTML(`width: ${ratio * 200}px`);
  }

  @computed("step.fields")
  get includeSidebar() {
    return this.step.fields.some((field) => field.show_in_sidebar);
  }

  autoFocus() {
    discourseLater(() => {
      schedule("afterRender", () => {
        if (document.querySelector(".invalid .wizard-focusable")) {
          this.animateInvalidFields();
        }
      });
    });
  }

  animateInvalidFields() {
    schedule("afterRender", () => {
      const invalid = document.querySelector(".invalid .wizard-focusable");
      if (invalid) {
        window.scrollTo({
          top: invalid.getBoundingClientRect().top + window.scrollY - 200,
          behavior: "smooth",
        });
      }
    });
  }

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
  }

  @action
  quit(event) {
    event?.preventDefault();
    this.wizard.skip();
  }

  @action
  done() {
    this.nextStep();
  }

  @action
  showMessage(message) {
    this.onShowMessage(message);
  }

  @action
  stepMessageChanged() {
    this.onShowMessage(this.step.message);
  }

  @action
  stylingDropdownChanged(id, value) {
    this.set("stylingDropdown", { id, value });
  }

  @action
  exitEarly() {
    const step = this.step;
    step.validate();

    if (step.get("valid")) {
      this.set("saving", true);

      step
        .save()
        .then(() => this.quit())
        .finally(() => this.set("saving", false));
    } else {
      this.autoFocus();
    }
  }

  @action
  backStep(event) {
    event?.preventDefault();

    if (this.saving) {
      return;
    }

    this.goBack();
  }

  @action
  nextStep() {
    if (this.saving) {
      return;
    }

    this.step.validate();

    if (this.step.get("valid")) {
      this.advance();
    } else {
      this.autoFocus();
    }
  }

  <template>
    <div
      class="wizard-step-contents"
      {{didUpdate this.stepMessageChanged this.step.message}}
    >
      {{#if this.step.title}}
        <h1 class="wizard-step-title">{{this.cookedTitle}}</h1>
      {{/if}}

      {{#if this.bannerImage}}
        <div class="wizard-step-banner">
          <img src={{this.bannerImage}} />
        </div>
      {{/if}}

      {{#if this.step.description}}
        <div class="wizard-step-description">{{this.cookedDescription}}</div>
      {{/if}}

      <CustomWizardStepForm @step={{this.step}}>
        {{#each this.step.fields as |field|}}
          <CustomWizardField
            @field={{field}}
            @step={{this.step}}
            @wizard={{this.wizard}}
          />
        {{/each}}
      </CustomWizardStepForm>
    </div>

    <div class="wizard-step-footer">

      <div class="wizard-progress">
        <div class="white"></div>
        <div class="black" style={{this.barStyle}}></div>
        <div class="screen"></div>
        <span>{{i18n
            "wizard.step"
            current=this.step.displayIndex
            total=this.wizard.totalSteps
          }}</span>
      </div>

      <div class="wizard-buttons">
        {{#if this.saving}}
          {{dLoadingSpinner size="small"}}
        {{else}}
          {{#if this.showQuitButton}}
            <a
              href
              {{on "click" this.quit}}
              class="action-link quit"
              tabindex={{this.secondaryButtonIndex}}
            >{{i18n "wizard.quit"}}</a>
          {{/if}}
          {{#if this.showBackButton}}
            <a
              href
              {{on "click" this.backStep}}
              class="action-link back"
              tabindex={{this.secondaryButtonIndex}}
            >{{i18n "wizard.back"}}</a>
          {{/if}}
        {{/if}}

        {{#if this.showNextButton}}
          <button
            type="button"
            class="wizard-btn next primary"
            {{on "click" this.nextStep}}
            disabled={{this.btnsDisabled}}
            tabindex={{this.primaryButtonIndex}}
          >
            {{i18n "wizard.next"}}
            {{dIcon "chevron-right"}}
          </button>
        {{/if}}

        {{#if this.showDoneButton}}
          <button
            type="button"
            class="wizard-btn done"
            {{on "click" this.done}}
            disabled={{this.btnsDisabled}}
            tabindex={{this.primaryButtonIndex}}
          >
            {{i18n "wizard.done_custom"}}
          </button>
        {{/if}}
      </div>

    </div>
  </template>
}
