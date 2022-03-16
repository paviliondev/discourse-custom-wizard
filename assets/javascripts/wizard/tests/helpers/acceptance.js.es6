import { module } from "qunit";
import setupPretender, { response } from "../pretender";
import startApp from "../helpers/start-app";

let server;
let app;

function acceptance(name, requests, cb) {
  module(`Acceptance: ${name}`, function (hooks) {
    hooks.beforeEach(function () {
      server = setupPretender(function (pretender) {
        requests.forEach((req) => {
          pretender[req.verb](req.path, () =>
            response(req.status, req.response)
          );
        });
        return pretender;
      });
      app = startApp();
    });

    hooks.afterEach(function () {
      app.destroy();
      server.shutdown();
    });

    cb(hooks);
  });
}

export default acceptance;

export { server };

// The discourse/test/helpers/qunit-helpers file has many functions and imports
// we don't need, so there will be some duplciation here.

export function queryAll(selector, context) {
  context = context || "#ember-testing";
  return $(selector, context);
}

export function query() {
  return document.querySelector("#ember-testing").querySelector(...arguments);
}

export function visible(selector) {
  return queryAll(selector + ":visible").length > 0;
}

export function count(selector) {
  return queryAll(selector).length;
}
