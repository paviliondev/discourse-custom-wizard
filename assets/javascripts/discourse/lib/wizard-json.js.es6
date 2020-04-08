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
  return advancedProperties.steps[property] && present(value);
}

function objectHasAdvanced(params, type) {
  return Object.keys(params).some(p => {
    let value = params[p];
    let advanced = advancedProperties[type][params.type];
    return advanced && advanced.indexOf(p) > -1 && present(value);
  });
}

/// to be removed
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
    props.id = json.id;
    props.existingId = true;
    
    // to fix
    properties.wizard
      .filter(p => ['steps', 'actions'].indexOf(p) === -1)
      .forEach((p) => {
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
        
        properties.steps.forEach((p) => {
          stepParams[p] = buildProperty(stepJson, p, 'wizard');
                    
          if (stepHasAdvanced(p, stepJson[p])) {
            stepParams.showAdvanced = true;
          }
        });
        
        stepParams.fields = A();
        
        if (present(stepJson.fields)) {
          stepJson.fields.forEach((f) => {
            let params = buildObject(f, 'fields');
                                    
            if (objectHasAdvanced(params, 'fields')) {
              params.showAdvanced = true;
            }
            
            stepParams.fields.pushObject(params);
          });
        }
        
        props.steps.pushObject(
          EmberObject.create(stepParams)
        );
      });
    };
    
    // to be removed
    json = actionPatch(json);
    // to be removed
  
    if (present(json.actions)) {
      json.actions.forEach((a) => {
        let params = buildObject(a, 'actions');
        
        if (objectHasAdvanced(params, 'actions')) {
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
  buildProperties,
  present,
  mapped
}