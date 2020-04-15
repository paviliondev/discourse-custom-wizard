import { registerUnbound } from 'discourse-common/lib/helpers';
import { dasherize } from "@ember/string";

registerUnbound('dasherize', function(string) {
  return dasherize(string);
});
