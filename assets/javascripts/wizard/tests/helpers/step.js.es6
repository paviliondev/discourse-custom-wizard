import updateJson from "../fixtures/update";
import { cloneJSON } from "discourse-common/lib/object";
import wizardJson from "../fixtures/wizard";

const update = cloneJSON(updateJson);
update.wizard = cloneJSON(wizardJson);

const saveStep = function (response) {
  return {
    verb: "put",
    path: "/w/wizard/steps/:step_id",
    status: 200,
    response,
  };
};

export { saveStep, update };
