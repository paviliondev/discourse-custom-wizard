import { registerUnbound } from "discourse-common/lib/helpers";
import I18n from "I18n";

export default registerUnbound("char-counter", function(body, maxLength) {
    let bodyLength = body ? body.length : 0; 
    let finalString;

    if (maxLength) {
       let isOverMax = bodyLength > maxLength ? "true" : "false";
       finalString = `<div class="body-length" data-length=${bodyLength} data-over-max=${isOverMax}>${bodyLength} / ${I18n.t('wizard.x_characters', { count: parseInt(maxLength) })}</div>`;
    } else {
       finalString = `<div class="body-length">${I18n.t('wizard.x_characters', { count: parseInt(bodyLength) })}</div>`;
    }

  return new Handlebars.SafeString(finalString);
});
