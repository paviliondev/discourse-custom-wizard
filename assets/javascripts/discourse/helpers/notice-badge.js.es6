import { autoUpdatingRelativeAge } from "discourse/lib/formatter";
import { iconHTML } from "discourse-common/lib/icon-library";
import I18n from "I18n";
import { registerUnbound } from "discourse-common/lib/helpers";
import { htmlSafe } from "@ember/template";

registerUnbound("notice-badge", function (attrs) {
  let tag = attrs.url ? "a" : "div";
  let attrStr = "";
  if (attrs.title) {
    attrStr += `title='${I18n.t(attrs.title)}'`;
  }
  if (attrs.url) {
    attrStr += `href='${attrs.url}'`;
  }
  let html = `<${tag} class="${
    attrs.class ? `${attrs.class} ` : ""
  }notice-badge" ${attrStr}>`;
  if (attrs.icon) {
    html += iconHTML(attrs.icon);
  }
  if (attrs.label) {
    if (attrs.icon) {
      html += "&nbsp;";
    }
    html += `<span>${I18n.t(attrs.label)}</span>`;
  }
  if (attrs.date) {
    if (attrs.icon || attrs.label) {
      html += "&nbsp;";
    }
    let dateAttrs = {};
    if (attrs.leaveAgo) {
      dateAttrs = {
        format: "medium",
        leaveAgo: true,
      };
    }
    html += autoUpdatingRelativeAge(new Date(attrs.date), dateAttrs);
  }
  html += `</${tag}>`;
  return htmlSafe(html);
});
