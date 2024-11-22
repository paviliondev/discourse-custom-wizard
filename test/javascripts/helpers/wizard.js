import { cloneJSON } from "discourse-common/lib/object";
import categoriesJson from "../fixtures/categories";
import groupsJson from "../fixtures/groups";
import updateJson from "../fixtures/update";
import userJson from "../fixtures/user";
import wizardJson from "../fixtures/wizard";

const wizardNoUser = cloneJSON(wizardJson);
const wizardGuest = cloneJSON(wizardJson);
wizardGuest.permitted = true;
const wizard = cloneJSON(wizardJson);
wizard.user = cloneJSON(userJson);
wizard.permitted = true;

const wizardNotPermitted = cloneJSON(wizard);
wizardNotPermitted.permitted = false;

const wizardCompleted = cloneJSON(wizard);
wizardCompleted.completed = true;

wizard.start = "step_1";
wizard.resume_on_revisit = false;
wizard.submission_last_updated_at = "2022-03-11T20:00:18+01:00";
wizard.subscribed = false;

const wizardResumeOnRevisit = cloneJSON(wizard);
wizardResumeOnRevisit.start = "step_2";
wizardResumeOnRevisit.resume_on_revisit = true;

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
  wizardGuest,
  wizardResumeOnRevisit,
  stepNotPermitted,
  allFieldsWizard,
  wizard,
  update,
};
