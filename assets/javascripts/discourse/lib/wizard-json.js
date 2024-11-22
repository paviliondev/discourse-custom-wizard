import { camelCase, listProperties } from "../lib/wizard";
import wizardSchema from "../lib/wizard-schema";
import EmberObject from "@ember/object";
import { A } from "@ember/array";

function present(val) {
  if (val === null || val === undefined) {
    return false;
  } else if (typeof val === "object") {
    return Object.keys(val).length !== 0;
  } else if (typeof val === "string" || val.constructor === Array) {
    return val && val.length;
  } else {
    return false;
  }
}

function mapped(property, type) {
  return wizardSchema[type].mapped.indexOf(property) > -1;
}

function castCase(property, value) {
  return property.indexOf("_type") > -1 ? camelCase(value) : value;
}

function buildMappedProperty(value) {
  let inputs = [];

  value.forEach((inputJson) => {
    let input = {};

    Object.keys(inputJson).forEach((inputKey) => {
      if (inputKey === "pairs") {
        let pairs = [];
        let pairCount = inputJson.pairs.length;

        inputJson.pairs.forEach((pairJson) => {
          let pair = {};

          Object.keys(pairJson).forEach((pairKey) => {
            pair[pairKey] = castCase(pairKey, pairJson[pairKey]);
          });

          pair.pairCount = pairCount;

          pairs.push(EmberObject.create(pair));
        });

        input.pairs = pairs;
      } else {
        input[inputKey] = castCase(inputKey, inputJson[inputKey]);
      }
    });

    inputs.push(EmberObject.create(input));
  });

  return A(inputs);
}

function buildProperty(json, property, type, objectIndex) {
  let value = json[property];
  if (
    property === "index" &&
    (value === null || value === undefined) &&
    (objectIndex !== null || objectIndex !== undefined)
  ) {
    return objectIndex;
  }

  if (
    !mapped(property, type) ||
    !present(value) ||
    !value.constructor === Array
  ) {
    return value;
  }

  return buildMappedProperty(value);
}

function buildObject(json, type, objectIndex) {
  let props = {
    isNew: false,
  };

  Object.keys(json).forEach((prop) => {
    props[prop] = buildProperty(json, prop, type, objectIndex);
  });

  return EmberObject.create(props);
}

function buildObjectArray(json, type) {
  let array = A();

  if (present(json)) {
    json.forEach((objJson, objectIndex) => {
      let object = buildObject(objJson, type, objectIndex);
      array.pushObject(object);
    });
  }

  return array;
}

function buildBasicProperties(json, type, props, objectIndex = null) {
  listProperties(type).forEach((p) => {
    props[p] = buildProperty(json, p, type, objectIndex);
  });

  return props;
}

/// to be removed: necessary due to action array being moved from step to wizard
function actionPatch(json) {
  let actions = json.actions || [];

  json.steps.forEach((step) => {
    if (step.actions && step.actions.length) {
      step.actions.forEach((action) => {
        action.run_after = "wizard_completion";
        actions.push(action);
      });
    }
  });

  json.actions = actions;

  return json;
}
///

function buildProperties(json) {
  let props = {
    steps: A(),
    actions: A(),
  };

  if (present(json)) {
    props.existingId = true;
    props = buildBasicProperties(json, "wizard", props);

    if (present(json.steps)) {
      json.steps.forEach((stepJson, objectIndex) => {
        let stepProps = {
          isNew: false,
        };

        stepProps = buildBasicProperties(
          stepJson,
          "step",
          stepProps,
          objectIndex
        );
        stepProps.fields = buildObjectArray(stepJson.fields, "field");

        props.steps.pushObject(EmberObject.create(stepProps));
      });
    }

    json = actionPatch(json); // to be removed - see above

    props.actions = buildObjectArray(json.actions, "action");
  } else {
    listProperties("wizard").forEach((prop) => {
      props[prop] = wizardSchema.wizard.basic[prop];
    });
  }

  return props;
}

export { buildProperties, present, mapped };
