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

function buildJson(object, type) {
  let result = {};
  
  properties[type].forEach((p) => {
    let value = object.get(p);
    
    if (mapped(p, type)) {
      value = buildMappedJson(value);
    } 

    if (value) {
      result[p] = value;
    }
  });
  
  return result;
}

function buildMappedJson(inputs) {
  if (!inputs || !inputs.length) return false;
  
  let result = [];
    
  inputs.forEach(inpt => {
    let input = {
      type: inpt.type,
    };
        
    if (present(inpt.output)) {
      input.output = inpt.output;
      input.output_type = snakeCase(inpt.output_type);
      input.output_connector = inpt.output_connector;
    }
    
    if (present(inpt.pairs)) {
      input.pairs = [];
      
      inpt.pairs.forEach(pr => {                
        if (present(pr.key) && present(pr.value)) {
          
          let pairParams = {
            index: pr.index,
            key: pr.key,
            key_type: snakeCase(pr.key_type),
            value: pr.value,
            value_type: snakeCase(pr.value_type),
            connector: pr.connector
          }
                    
          input.pairs.push(pairParams);
        }
      });
    }
        
    if ((input.type === 'assignment' && present(input.output)) ||
        present(input.pairs)) {
      
      result.push(input);
    }
  });
  
  if (!result.length) {
    result = false;
  }
    
  return result;
}

function buildStepJson(object) {
  let steps = [];
  let error = null;

  object.some((s) => {
    let step = buildJson(s, 'step');
    let fields = s.fields;
          
    if (fields.length) {
      step.fields = [];

      fields.some((f) => {
        if (!f.type) {
          error = 'type_required';
          return;
        }

        step.fields.push(
          buildJson(f, 'field')
        );
      });

      if (error) return;
    }
    
    let actions = s.actions;
    
    if (actions.length) {
      step.actions = [];

      actions.some((a) => {          
        if (a.api_body) {
          try {
            JSON.parse(a.api_body);
          } catch (e) {
            error = 'invalid_api_body';
            return;
          }
        }

        step.actions.push(
          buildJson(a, 'action')
        );
      });

      if (error) return;
    }
    
    steps.push(step);
  });
  
  if (error) {
    return { error };
  } else {
    return { steps };
  };
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
  let steps = A();
  let props = { 
    steps
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

        stepParams.actions = A();
        
        if (present(stepJson.actions)) {
          stepJson.actions.forEach((a) => {
            let params = buildObject(a, 'action');
            
            if (objectHasAdvanced(params, 'action')) {
              params.showAdvanced = true;
            }
            
            stepParams.actions.pushObject(params);
          });
        }

        steps.pushObject(
          EmberObject.create(stepParams)
        );
      });
    };
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
    props.steps = A();
  }
  
  return props;
}

export {
  buildStepJson,
  buildJson,
  buildProperties
}