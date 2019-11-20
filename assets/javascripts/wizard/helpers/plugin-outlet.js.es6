import { registerUnbound } from "discourse-common/lib/helpers";

export default registerUnbound("plugin-outlet", function(attrs) {
  return new Handlebars.SafeString('');
});