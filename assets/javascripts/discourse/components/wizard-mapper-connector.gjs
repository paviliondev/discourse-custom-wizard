/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { action, computed } from "@ember/object";
import { later } from "@ember/runloop";
import { classNameBindings } from "@ember-decorators/component";
import ComboBox from "discourse/select-kit/components/combo-box";
import { i18n } from "discourse-i18n";
import { defaultConnector } from "../lib/wizard-mapper";

@classNameBindings(":mapper-connector", ":mapper-block", "hasMultiple::single")
export default class WizardMapperConnector extends Component {
  @computed("connectors.length")
  get hasMultiple() {
    return this.connectors?.length > 1;
  }

  @computed("connector", "inputTypes")
  get connectorLabel() {
    let key = this.connector;
    let path = this.inputTypes ? `input.${key}.name` : `connector.${key}`;
    return i18n(`admin.wizard.${path}`);
  }

  didReceiveAttrs() {
    super.didReceiveAttrs(...arguments);
    if (!this.connector) {
      later(() => {
        this.set(
          "connector",
          defaultConnector(this.connectorType, this.inputType, this.options)
        );
      });
    }
  }

  @action
  changeConnector(value) {
    this.set("connector", value);
    this.onChange?.(value);
    this.onUpdate("connector", this.connectorType);
  }

  <template>
    {{#if this.hasMultiple}}
      <ComboBox
        @value={{this.connector}}
        @content={{this.connectors}}
        @onChange={{this.changeConnector}}
      />
    {{else}}
      {{#if this.connector}}
        <span class="connector-single">
          {{this.connectorLabel}}
        </span>
      {{/if}}
    {{/if}}
  </template>
}
