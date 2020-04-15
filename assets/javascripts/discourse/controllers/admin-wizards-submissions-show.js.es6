import Controller from "@ember/controller";
import { fmt } from "discourse/lib/computed";

export default Controller.extend({
  downloadUrl: fmt("wizard.id", "/admin/wizards/submissions/%@/download")
});