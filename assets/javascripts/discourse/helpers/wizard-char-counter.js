import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";

export default function wizardCharCounter(body, maxLength) {
  let bodyLength = body ? body.length : 0;
  let finalString;

  if (maxLength) {
    let isOverMax = bodyLength > maxLength ? "true" : "false";
    finalString = `<div class="body-length" data-length=${bodyLength} data-over-max=${isOverMax}>${bodyLength} / ${i18n(
      "wizard.x_characters",
      { count: parseInt(maxLength, 10) }
    )}</div>`;
  } else {
    finalString = `<div class="body-length">${i18n("wizard.x_characters", {
      count: parseInt(bodyLength, 10),
    })}</div>`;
  }

  return htmlSafe(finalString);
}
