import { properties, mappedProperties, advancedProperties, camelCase, snakeCase } from '../lib/wizard';
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
  return mappedProperties[type] &&
    mappedProperties[type].indexOf(property) > -1;
}

function castCase(property, value) {
  return property.indexOf('_type') > -1 ? camelCase(value) : value;
}

function buildProperty(json, property, type) {  
  if (mapped(property, type) && present(json[property])) {
    let inputs = [];
    
    json[property].forEach(inputJson => {
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
    return json[property];
  }
}

function buildObject(json, type) {
  let params = {
    isNew: false
  }
  
  Object.keys(json).forEach(prop => {
    params[prop] = buildProperty(json, prop, type)
  });
  
  return EmberObject.create(params);
}

function wizardHasAdvanced(property, value) {
  if (property === 'save_submissions' && value == false) return true;
  if (property === 'restart_on_revisit' && value == true) return true;
  return false;
}

function stepHasAdvanced(property, value) {
  return advancedProperties.step[property] && present(value);
}

function objectHasAdvanced(params, type) {
  return Object.keys(params).some(p => {
    let value = params[p];
    let advanced = advancedProperties[type][params.type];
    return advanced && advanced.indexOf(p) > -1 && present(value);
  });
}

function buildProperties(json) {
  let props = { 
    steps: A();
    action: A();
  };
    
  if (present(json)) {
    props.id = json.id;
    props.existingId = true;

    properties.wizard.forEach((p) => {
      props[p] = buildProperty(json, p, 'wizard');
      
      if (wizardHasAdvanced(p, json[p])) {
        props.showAdvanced = true;
      }
    });

    if (present(json.steps)) {
      json.steps.forEach((stepJson) => {
        let stepParams = {
          isNew: false
        };
        
        properties.step.forEach((p) => {
          stepParams[p] = buildProperty(stepJson, p, 'wizard');
                    
          if (stepHasAdvanced(p, stepJson[p])) {
            stepParams.showAdvanced = true;
          }
        });
        
        stepParams.fields = A();
        
        if (present(stepJson.fields)) {
          stepJson.fields.forEach((f) => {
            let params = buildObject(f, 'field');
                                    
            if (objectHasAdvanced(params, 'field')) {
              params.showAdvanced = true;
            }
            
            stepParams.fields.pushObject(params);
          });
        }

        steps.pushObject(
          EmberObject.create(stepParams)
        );
      });
    };
        
    if (present(json.actions)) {
      json.actions.forEach((a) => {
        let params = buildObject(a, 'action');
        
        if (objectHasAdvanced(params, 'action')) {
          params.showAdvanced = true;
        }
        
        props.actions.pushObject(params);
      });
    }
  } else {
    props.id = '';
    props.name = '';
    props.background = '';
    props.save_submissions = true;
    props.multiple_submissions = false;
    props.after_signup = false;
    props.after_time = false;
    props.required = false;
    props.prompt_completion = false;
    props.restart_on_revisit = false;
    props.permitted = null;
  }
  
  return props;
}

export {
  buildStepJson,
  buildJson,
  buildProperties
}