export default {
  name: "custom-wizard-redirect",
  after: "message-bus",

  initialize: function (container) {
    const messageBus = container.lookup('message-bus:main');

    if (!messageBus) { return; }

    messageBus.subscribe("/redirect_to_wizard", function (wizardId) {
      const wizardUrl = window.location.origin + '/w/' + wizardId;
      window.location.href = wizardUrl;
    });
  }
};
