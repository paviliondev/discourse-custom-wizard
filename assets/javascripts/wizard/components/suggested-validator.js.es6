import WizardFieldValidator from "../../wizard/components/validator";
import { ajax } from "discourse/lib/ajax";
import { getToken } from "wizard/lib/ajax";
import { getOwner } from "discourse-common/lib/get-owner";
import discourseComputed from "discourse-common/utils/decorators";

export default WizardFieldValidator.extend({
    validMessageKey: 'hello',
    invalidMessageKey: 'world',
    validate() {
        this.backendValidate({title: this.get("field.value")}).then(response => {
            console.log(response)
        })
    },

    init() {
        this._super(...arguments);
       
    }
});