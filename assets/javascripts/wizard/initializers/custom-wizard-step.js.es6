export default {
  name: "custom-wizard-step",
  initialize(app) {
    if (window.location.pathname.indexOf("/w/") < 0) return;
    
    const CustomWizard = requirejs("discourse/plugins/discourse-custom-wizard/wizard/models/custom").default;
    const StepModel = requirejs("wizard/models/step").default;
    const StepComponent = requirejs("wizard/components/wizard-step").default;
    const ajax = requirejs("wizard/lib/ajax").ajax;
    const cook = requirejs("discourse/plugins/discourse-custom-wizard/wizard/lib/text-lite").cook;
    
    StepModel.reopen({
      save() {
        const wizardId = this.get("wizardId");
        const fields = {};

        this.get("fields").forEach((f) => {
          if (f.type !== "text_only") {
            fields[f.id] = f.value;
          }
        });

        return ajax({
          url: `/w/${wizardId}/steps/${this.get("id")}`,
          type: "PUT",
          data: { fields },
        }).catch((response) => {
          if (
            response &&
            response.responseJSON &&
            response.responseJSON.errors
          ) {
            let wizardErrors = [];
            response.responseJSON.errors.forEach((err) => {
              if (err.field === wizardId) {
                wizardErrors.push(err.description);
              } else if (err.field) {
                this.fieldError(err.field, err.description);
              } else if (err) {
                wizardErrors.push(err);
              }
            });
            if (wizardErrors.length) {
              this.handleWizardError(wizardErrors.join("\n"));
            }
            this.animateInvalidFields();
            throw response;
          }

          if (response && response.responseText) {
            const responseText = response.responseText;
            const start = responseText.indexOf(">") + 1;
            const end = responseText.indexOf("plugins");
            const message = responseText.substring(start, end);
            this.handleWizardError(message);
            throw message;
          }
        });
      },

      handleWizardError(message) {
        this.set("message", {
          state: "error",
          text: message,
        });
        Ember.run.later(() => this.set("message", null), 6000);
      },
    });
    
    StepComponent.reopen({
      classNameBindings: ["step.id"],

      animateInvalidFields() {
        Ember.run.scheduleOnce("afterRender", () => {
          let $element = $(".invalid input[type=text],.invalid textarea,.invalid input[type=checkbox],.invalid .select-kit");

          if ($element.length) {
            $([document.documentElement, document.body]).animate(
              {
                scrollTop: $element.offset().top - 200,
              },
              400,
              function () {
                $element.wiggle(2, 100);
              }
            );
          }
        });
      },

      ensureStartsAtTop: function () {
        window.scrollTo(0, 0);
      }.observes("step.id"),

      showQuitButton: function () {
        const index = this.get("step.index");
        const required = this.get("wizard.required");
        return index === 0 && !required;
      }.property("step.index", "wizard.required"),

      cookedTitle: function () {
        return cook(this.get("step.title"));
      }.property("step.title"),

      cookedDescription: function () {
        return cook(this.get("step.description"));
      }.property("step.description"),

      bannerImage: function () {
        const src = this.get("step.banner");
        if (!src) return;
        return getUrl(src);
      }.property("step.banner"),

      handleMessage: function () {
        const message = this.get("step.message");
        this.sendAction("showMessage", message);
      }.observes("step.message"),

      advance() {
        this.set("saving", true);
        this.get("step")
          .save()
          .then((response) => {
            if (this.get("finalStep")) {
              CustomWizard.finished(response);
            } else {
              this.sendAction("goNext", response);
            }
          })
          .catch(() => this.animateInvalidFields())
          .finally(() => this.set("saving", false));
      },

      keyPress(key) {},

      actions: {
        quit() {
          this.get("wizard").skip();
        },

        done() {
          this.set("finalStep", true);
          this.send("nextStep");
        },

        showMessage(message) {
          this.sendAction("showMessage", message);
        },
      },
    });
  }
}