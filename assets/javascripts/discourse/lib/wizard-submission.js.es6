import EmberObject from "@ember/object";

function formatModel(model) {
  let fields = [
    EmberObject.create({
      id: "submitted_at",
      label: "Submitted At",
      enabled: true,
    }),
    EmberObject.create({ id: "username", label: "User", enabled: true }),
  ];
  let submissions = [];

  model.submissions.forEach((s) => {
    let submission = {
      submitted_at: s.submitted_at,
      username: s.user,
    };

    Object.keys(s.fields).forEach((fieldId) => {
      if (!fields.some((field) => field.id === fieldId)) {
        fields.push(
          EmberObject.create({
            id: fieldId,
            label: s.fields[fieldId].label,
            enabled: true,
          })
        );
      }
      submission[fieldId] = s.fields[fieldId];
    });

    submissions.push(EmberObject.create(submission));
  });

  return { fields, submissions };
}

export { formatModel };
