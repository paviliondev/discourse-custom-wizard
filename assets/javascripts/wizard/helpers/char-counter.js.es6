import { registerUnbound } from "discourse-common/lib/helpers";
import I18n from "I18n";

export default registerUnbound("char-counter", function(body, maxLength) {
    let bodyLength = body ? body.length : 0; 
    let finalString;

    if (maxLength) {
       finalString = `<div class="body-length">${bodyLength} / ${I18n.t('wizard.x_characters', { count: parseInt(maxLength) })}</div>`;
    } else {
       finalString = `<div class="body-length">${I18n.t('wizard.x_characters', { count: parseInt(bodyLength) })}</div>`;
    }

  return new Handlebars.SafeString(finalString);
});
