import Component from "@ember/component";
import { observes } from "discourse-common/utils/decorators";
export default Component.extend({
    actions:{
        perform() {
            this.appEvents.trigger('custom-wizard:validate');
        }
    },
});