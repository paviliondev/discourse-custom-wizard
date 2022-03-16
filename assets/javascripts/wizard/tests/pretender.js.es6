import Pretender from "pretender";

function response(code, obj) {
  if (typeof code === "object") {
    obj = code;
    code = 200;
  }
  return [code, { "Content-Type": "application/json" }, obj];
}

export { response };

export default function (cb) {
  let server = new Pretender();

  if (cb) {
    server = cb(server);
  }

  server.prepareBody = function (body) {
    if (body && typeof body === "object") {
      return JSON.stringify(body);
    }
    return body;
  };

  server.unhandledRequest = function (verb, path) {
    const error =
      "Unhandled request in test environment: " + path + " (" + verb + ")";
    window.console.error(error);
    throw error;
  };

  return server;
}
