import TextareaEditor from "discourse/components/composer/textarea-editor";

export default class CustomWizardTextareaEditor extends TextareaEditor {
  setupSmartList() {
    // These must be bound manually because itsatrap does not support
    // beforeinput or input events.
    //
    // beforeinput is better used to detect line breaks because it is
    // fired before the actual value of the textarea is changed,
    // and sometimes in the input event no `insertLineBreak` event type
    // is fired.
    //
    // c.f. https://developer.mozilla.org/en-US/docs/Web/API/Element/beforeinput_event
    if (this.currentUser?.user_option.enable_smart_lists) {
      this.textarea.addEventListener(
        "beforeinput",
        this.onBeforeInputSmartList
      );
      this.textarea.addEventListener(
        "keydown",
        this.onBeforeInputSmartListShiftDetect
      );
      this.textarea.addEventListener("input", this.onInputSmartList);
    }
  }

  destroySmartList() {
    if (this.currentUser?.user_option.enable_smart_lists) {
      this.textarea.removeEventListener(
        "beforeinput",
        this.onBeforeInputSmartList
      );
      this.textarea.removeEventListener(
        "keydown",
        this.onBeforeInputSmartListShiftDetect
      );
      this.textarea.removeEventListener("input", this.onInputSmartList);
    }
  }
}
