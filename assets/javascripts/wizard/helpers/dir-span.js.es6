import { registerUnbound } from "discourse-common/lib/helpers";

export default registerUnbound("dir-span", function(str) {
  return new Handlebars.SafeString(str);
});