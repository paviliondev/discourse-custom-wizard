import wizardJson from "../fixtures/wizard";
import userJson from "../fixtures/user";
import categoriesJson from "../fixtures/categories";
import groupsJson from "../fixtures/groups";
import updateJson from "../fixtures/update";
import { cloneJSON } from "discourse-common/lib/object";

const wizardNoUser = cloneJSON(wizardJson);
const wizard = cloneJSON(wizardJson);
wizard.user = cloneJSON(userJson);

const wizardNotPermitted = cloneJSON(wizard);
wizardNotPermitted.permitted = false;

const wizardCompleted = cloneJSON(wizard);
wizardCompleted.completed = true;

wizard.start = "step_1";
wizard.resume_on_revisit = false;
wizard.submission_last_updated_at = "2022-03-11T20:00:18+01:00";
wizard.subscribed = false;

const stepNotPermitted = cloneJSON(wizard);
stepNotPermitted.steps[0].permitted = false;

const allFieldsWizard = cloneJSON(wizard);
allFieldsWizard.steps[0].fields = [
  ...allFieldsWizard.steps[0].fields,
  ...allFieldsWizard.steps[1].fields,
  ...allFieldsWizard.steps[2].fields,
];
allFieldsWizard.steps = [cloneJSON(allFieldsWizard.steps[0])];
allFieldsWizard.categories = cloneJSON(categoriesJson["categories"]);
allFieldsWizard.groups = cloneJSON(groupsJson["groups"]);

const update = cloneJSON(updateJson);
update.wizard = cloneJSON(wizard);

export {
  wizardNoUser,
  wizardNotPermitted,
  wizardCompleted,
  stepNotPermitted,
  allFieldsWizard,
  wizard,
  update,
};
