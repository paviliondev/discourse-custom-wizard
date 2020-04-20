import { listProperties, camelCase, snakeCase } from '../lib/wizard';
import wizardSchema from '../lib/wizard-schema';
import EmberObject from '@ember/object';
import { A } from "@ember/array";

function present(val) {
  if (val === null || val === undefined) {
    return false;
  } else if (typeof val === 'object') {
    return Object.keys(val).length !== 0;
  } else if (typeof val === 'string' || val.constructor === Array) {
    return val && val.length;
  } else {
    return false;
  }
}

function mapped(property, type) {
  return wizardSchema[type].mapped.indexOf(property) > -1;
}

function castCase(property, value) {
  return property.indexOf('_type') > -1 ? camelCase(value) : value;
}

function buildProperty(json, property, type) {
  let value = json[property];
  
  if (mapped(property, type) &&
      present(value) &&
      value.constructor === Array) {
    
    let inputs = [];
        
    value.forEach(inputJson => {
      let input = {}
      
      Object.keys(inputJson).forEach(inputKey => {
        if (inputKey === 'pairs') {
          let pairs = [];
          let pairCount = inputJson.pairs.length;
          
          inputJson.pairs.forEach(pairJson => {
            let pair = {};
            
            Object.keys(pairJson).forEach(pairKey => {
              pair[pairKey] = castCase(pairKey,  pairJson[pairKey]);
            });
            
            pair.pairCount = pairCount;
            
            pairs.push(
              EmberObject.create(pair)
            );
          });
          
          input.pairs = pairs;
        } else {
          input[inputKey] = castCase(inputKey,  inputJson[inputKey]);
        }
      });
      
      inputs.push(
        EmberObject.create(input)
      );
    });
    
    return A(inputs);
  } else {
    return value;
  }
}

function buildObject(json, type) {
  let props = {
    isNew: false
  }
  
  Object.keys(json).forEach(prop => {
    props[prop] = buildProperty(json, prop, type)
  });
    
  return EmberObject.create(props);
}

function buildObjectArray(json, type) {
  let array = A();
  
  if (present(json)) {
    json.forEach((objJson) => {
      let object = buildObject(objJson, type);
      
      if (hasAdvancedProperties(object, type)) {
        object.set('showAdvanced', true);
      }
      
      array.pushObject(object);
    });
  }
  
  return array;
}

function buildBasicProperties(json, type, props) {
  listProperties(type).forEach((p) => {
    props[p] = buildProperty(json, p, type);
    
    if (hasAdvancedProperties(json, type)) {
      props.showAdvanced = true;
    }
  });
  
  return props;
}

function hasAdvancedProperties(object, type) {
  return Object.keys(object).some(p => {
    return wizardSchema[type].advanced.indexOf(p) > -1 && present(object[p]);
  });
}

/// to be removed: necessary due to action array being moved from step to wizard
function actionPatch(json) {
  let actions = json.actions || [];
  
  json.steps.forEach(step => {
    if (step.actions && step.actions.length) {
      step.actions.forEach(action => {
        action.run_after = 'wizard_completion';
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
    actions: A()
  };
        
  if (present(json)) {
    props.existingId = true;
    props = buildBasicProperties(json, 'wizard', props);
    
    if (present(json.steps)) {
      json.steps.forEach((stepJson) => {
        let stepProps = {
          isNew: false
        };
  
        stepProps = buildBasicProperties(stepJson, 'step', stepProps);
        stepProps.fields = buildObjectArray(stepJson.fields, 'field');
        
        props.steps.pushObject(EmberObject.create(stepProps));
      });
    };

    json = actionPatch(json); // to be removed - see above
    
    props.actions = buildObjectArray(json.actions, 'action');
  } else {
    listProperties('wizard').forEach(prop => {
      props[prop] = wizardSchema.wizard.basic[prop];
    });
  }
    
  return props;
}

export {
  buildProperties,
  present,
  mapped
}