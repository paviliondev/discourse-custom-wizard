import loadScript from './load-script';
import { default as PrettyText } from 'pretty-text/pretty-text';

export function cook(text, options) {
  return new Handlebars.SafeString(new PrettyText(options).cook(text));
}

// everything should eventually move to async API and this should be renamed
// cook
export function cookAsync(text, options) {
  if (Discourse.MarkdownItURL) {
    return loadScript(Discourse.MarkdownItURL)
      .then(()=>cook(text, options))
      .catch(e => Ember.Logger.error(e));
  } else {
    return Ember.RSVP.Promise.resolve(cook(text));
  }
}
