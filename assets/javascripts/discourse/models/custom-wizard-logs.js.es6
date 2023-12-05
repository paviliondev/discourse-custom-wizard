import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmberObject from "@ember/object";

const CustomWizardLogs = EmberObject.extend();
const logItemTypes = {
  date: "date_time",
  action: "text",
  message: "long_text",
  user: "user",
  username: "text",
};

function logItem(item, attr) {
  return {
    value: item[attr],
    type: logItemTypes[attr],
  };
}

CustomWizardLogs.reopenClass({
  list(wizardId, page = 0) {
    let data = {
      page,
    };

    return ajax(`/admin/wizards/logs/${wizardId}`, { data })
      .catch(popupAjaxError)
      .then((result) => {
        if (result.logs) {
          result.logs = result.logs.map((item) => {
            let map = {};

            if (item.date) {
              map.date = logItem(item, "date");
            }
            if (item.action) {
              map.action = logItem(item, "action");
            }
            if (item.user) {
              map.user = item.user;
            } else {
              map.user = logItem(item, "username");
            }
            if (item.message) {
              map.message = logItem(item, "message");
            }

            return map;
          });
        }
        return result;
      });
  },
});

export default CustomWizardLogs;
