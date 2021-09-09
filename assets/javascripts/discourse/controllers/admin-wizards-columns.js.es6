import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  actions: {
    save() {
      this.send("closeModal");
    },

    resetToDefault() {
      this.get("model.reset")();
    },
  },
});
