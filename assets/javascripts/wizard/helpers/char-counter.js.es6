import { registerUnbound } from "discourse-common/lib/helpers";
import I18n from "I18n";

export default registerUnbound("char-counter", function(body, maxLength) {
    let bodyLength = body ? body.length : 0; 
    let length = maxLength || bodyLength;
    let characterString = length == 1 ? 'wizard.character' : 'wizard.characters';
    let finalString;

    if(maxLength) {
       finalString = `<div class="body-length">${bodyLength} / ${maxLength} ${ I18n.t(characterString)}</div>`;
    } else {
       finalString = `<div class="body-length">${bodyLength} ${ I18n.t(characterString)}</div>`;
    }
  return new Handlebars.SafeString(finalString);
});
