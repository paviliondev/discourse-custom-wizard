import { hash } from "@ember/helper";
import ComboBox from "discourse/select-kit/components/combo-box";
import DTimeInput from "discourse/ui-kit/d-time-input";

export default class CustomWizardTimeInput extends DTimeInput {
  <template>
    <ComboBox
      @value={{this.time}}
      @content={{this.timeOptions}}
      @tabindex={{@tabindex}}
      @onChange={{this.onChangeTime}}
      @options={{hash
        translatedNone="--:--"
        allowAny=true
        filterable=false
        autoInsertNoneItem=false
        translatedFilterPlaceholder="--:--"
      }}
    />
  </template>
}
