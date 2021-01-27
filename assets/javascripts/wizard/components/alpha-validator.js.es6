import WizardFieldValidator from "../../wizard/components/validator";

export default WizardFieldValidator.extend({
    validMessageKey: 'hello',
    invalidMessageKey: 'world',
    validate() {
        if(this.field.value) {
            this.field.value.length > 0 ? this.set('isValid', true) : this.set('isValid', false); 
        } else {
            this.set('isValid', false);
        }
    }
});