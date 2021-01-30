import Component from "@ember/component";

export default Component.extend({
    init(){
        this._super(...arguments);
        if (!this.validations) return;

        if (!this.field.validations) {
            const validations = {};
            this.validations.forEach((validation) => {
                validations[validation] = {};
            });

            this.set('field.validations', EmberObject.create(validations));
        }
    }
});
