import { registerUnbound } from "discourse-common/lib/helpers";
import I18n from "I18n";

export default registerUnbound("char-counter", function(body) {
    let bodyLength = body ? body.length : 0; 
    let characterString = bodyLength == 1 ? 'wizard.character' : 'wizard.characters';
    let finalString = `<div class="body-length">${bodyLength} ${ I18n.t(characterString)}</div>`;
  return new Handlebars.SafeString(finalString);
});