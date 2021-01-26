import Component from "@ember/component";
import { observes } from "discourse-common/utils/decorators";
export default Component.extend({
    actions:{
        perform() {
            this.toggleProperty('performValidation');
        }
    }
});