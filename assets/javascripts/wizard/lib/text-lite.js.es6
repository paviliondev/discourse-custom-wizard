import loadScript from "./load-script";
import { default as PrettyText, buildOptions } from "pretty-text/pretty-text";
import Handlebars from "handlebars";
import getURL from "discourse-common/lib/get-url";
import { getOwner } from "discourse-common/lib/get-owner";

export function cook(text, options) {
  if (!options) {
    options = buildOptions({
      getURL,
      siteSettings: getOwner(this).lookup("site-settings:main"),
    });
  }

  return new Handlebars.SafeString(new PrettyText(options).cook(text));
}

// everything should eventually move to async API and this should be renamed
// cook
export function cookAsync(text, options) {
  if (Discourse.MarkdownItURL) {
    return loadScript(Discourse.MarkdownItURL)
      .then(() => cook(text, options))
      .catch((e) => Ember.Logger.error(e));
  } else {
    return Ember.RSVP.Promise.resolve(cook(text));
  }
}
