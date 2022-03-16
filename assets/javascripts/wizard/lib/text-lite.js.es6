import loadScript from "./load-script";
import { default as PrettyText, buildOptions } from "pretty-text/pretty-text";
import Handlebars from "handlebars";
import getURL from "discourse-common/lib/get-url";
import { getOwner } from "discourse-common/lib/get-owner";
import { Promise } from "rsvp";
import Session from "discourse/models/session";

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
  let markdownItURL = Session.currentProp("markdownItURL");
  if (markdownItURL) {
    return (
      loadScript(markdownItURL)
        .then(() => cook(text, options))
        // eslint-disable-next-line no-console
        .catch((e) => console.error(e))
    );
  } else {
    return Promise.resolve(cook(text));
  }
}
