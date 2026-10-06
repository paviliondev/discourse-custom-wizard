/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { hash } from "@ember/helper";
import { action, computed } from "@ember/object";
import { makeArray } from "discourse/lib/helpers";
import ComboBox from "discourse/select-kit/components/combo-box";

export default class CustomWizardFieldDropdown extends Component {
  keyPress(e) {
    e.stopPropagation();
  }

  @computed("field.content")
  get content() {
    return makeArray(this.field.content)
      .filter((item) => item !== null && item !== undefined)
      .map((item) =>
        typeof item === "object" ? item : { id: item, name: `${item}` }
      );
  }

  @action
  onChangeValue(value) {
    this.set("field.value", value);
  }

  <template>
    <ComboBox
      @class={{this.fieldClass}}
      @value={{this.field.value}}
      @content={{this.content}}
      @tabindex={{this.field.tabindex}}
      @onChange={{this.onChangeValue}}
      @options={{hash none="select_kit.default_header_text"}}
    />
  </template>
}
