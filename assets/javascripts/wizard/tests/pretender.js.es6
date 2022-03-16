import Pretender from "pretender";

function parsePostData(query) {
  const result = {};
  query.split("&").forEach(function (part) {
    const item = part.split("=");
    const firstSeg = decodeURIComponent(item[0]);
    const m = /^([^\[]+)\[([^\]]+)\]/.exec(firstSeg);

    const val = decodeURIComponent(item[1]).replace(/\+/g, " ");
    if (m) {
      result[m[1]] = result[m[1]] || {};
      result[m[1]][m[2]] = val;
    } else {
      result[firstSeg] = val;
    }
  });
  return result;
}

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

  server.unhandledRequest = function (verb, path, request) {
    const error =
      "Unhandled request in test environment: " + path + " (" + verb + ")";
    window.console.error(error);
    throw error;
  };

  return server;
}
