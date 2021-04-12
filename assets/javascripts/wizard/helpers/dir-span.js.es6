import { registerUnbound } from "discourse-common/lib/helpers";
import Handlebars from "handlebars";

export default registerUnbound("dir-span", function (str) {
  return new Handlebars.SafeString(str);
});
