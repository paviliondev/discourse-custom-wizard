import { registerUnbound } from 'discourse-common/lib/helpers';

registerUnbound('dasherize', function(string) {
  return Ember.String.dasherize(string);
});
