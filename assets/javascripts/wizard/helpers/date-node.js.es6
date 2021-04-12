import { registerUnbound } from "discourse-common/lib/helpers";
import { longDate, relativeAge } from "discourse/lib/formatter";
import Handlebars from "handlebars";

export default registerUnbound("date-node", function (dt) {
  if (typeof dt === "string") {
    dt = new Date(dt);
  }
  if (dt) {
    const attributes = {
      title: longDate(dt),
      "data-time": dt.getTime(),
      "data-format": "tiny",
    };

    const finalString = `<span class="relative-date" title="${
      attributes["title"]
    }" data-time="${attributes["data-time"]}" data-format="${
      attributes["data-format"]
    }">${relativeAge(dt)}</span>`;
    return new Handlebars.SafeString(finalString);
  }
});
