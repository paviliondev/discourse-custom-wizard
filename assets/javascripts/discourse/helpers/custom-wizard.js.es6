import { registerUnbound } from 'discourse-common/lib/helpers';

registerUnbound('dasherize', function(string) {
  console.log(string)
  return Ember.String.dasherize(string);
});
