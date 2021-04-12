import { registerUnbound } from "discourse-common/lib/helpers";
import Handlebars from "handlebars";

export default registerUnbound("plugin-outlet", function () {
  return new Handlebars.SafeString("");
});
