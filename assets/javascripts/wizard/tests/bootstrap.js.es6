// discourse-skip-module
/*global document, Logster */

if (window.location.pathname.indexOf("/w/") > -1 && Ember.testing) {
  document.addEventListener("DOMContentLoaded", function () {
    document.body.insertAdjacentHTML(
      "afterbegin",
      `
        <div id="ember-testing-container"><div id="ember-testing"></div></div>
        <style>#ember-testing-container { position: absolute; background: white; bottom: 0; right: 0; width: 640px; height: 384px; overflow: auto; z-index: 9999; border: 1px solid #ccc; } #ember-testing { zoom: 50%; }</style>
      `
    );
  });

  Object.keys(requirejs.entries).forEach(function (entry) {
    if (/\-test/.test(entry)) {
      requirejs(entry);
    }
  });

  if (window.Logster) {
    Logster.enabled = false;
  } else {
    window.Logster = { enabled: false };
  }
}
