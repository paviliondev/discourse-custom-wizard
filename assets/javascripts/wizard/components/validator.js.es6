import Component from "@ember/component";
import { not } from "@ember/object/computed";
import { observes } from "discourse-common/utils/decorators";

export default Component.extend({
    classNameBindings: ['isValid', 'isInvalid'],
    validMessageKey: null,
    invalidMessageKey: null,
    isValid: null,
    isInvalid: not('isValid'),
    layoutName: 'components/validator', // useful for sharing the template with extending components
    didInsertElement() {
      this.appEvents.on('custom-wizard:validate', this, this.validate);
    },

    willDestroyElement() {
      this.appEvents.off('custom-wizard:validate', this, this.validate);
    }
});