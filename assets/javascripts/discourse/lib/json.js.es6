import { properties } from '../lib/custom-wizard';
import { mappedProperties } from '../lib/mapper';
import EmberObject from '@ember/object';

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
      input.output_type = inpt.output_type;
      input.connector = inpt.connector;
    }
    
    if (present(inpt.pairs)) {
      input.pairs = [];
      
      inpt.pairs.forEach(pr => {                
        if (present(pr.key) && present(pr.value)) {
          
          let pairParams = {
            index: pr.index,
            key: pr.key,
            key_type: pr.key_type,
            value: pr.value,
            value_type: pr.value_type,
            connector: pr.connector
          }
                    
          input.pairs.push(pairParams);
        }
      });
    }
        
    if ((input.type === 'assignment' && present(input.output)) ||
        (input.type === 'conditional' && present(input.pairs)) ||
        (input.type === 'pair' && present(input.pairs))) {
      
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

function buildObject(json, type) {
  let params = {
    isNew: false
  }
  
  Object.keys(json).forEach(prop => {
    if (mapped(prop, type)) {
      let inputs = [];
      
      if (present(json[prop])) {
        json[prop].forEach(inputJson => {
          let input = {}
          
          Object.keys(inputJson).forEach(inputKey => {
            if (inputKey === 'pairs') {
              let pairs = [];
              let pairCount = inputJson.pairs.length;
              
              inputJson.pairs.forEach(pairJson => {
                let pair = pairJson;
                pair.pairCount = pairCount;
                
                pairs.push(
                  EmberObject.create(pair)
                );
              });
              
              input.pairs = pairs;
            } else {
              input[inputKey] = inputJson[inputKey];
            }
          });
          
          inputs.push(
            EmberObject.create(input)
          );
        });
      }
      
      params[prop] = Ember.A(inputs);
    } else {
      params[prop] = json[prop];
    }
  });
  
  return EmberObject.create(params);
}

function buildProperties(json) {
  let steps = Ember.A();
  let props = { 
    steps
  };
    
  if (present(json)) {
    props.id = json.id;
    props.existingId = true;

    properties.wizard.forEach((p) => {
      props[p] = json[p];
    });

    if (present(json.steps)) {
      json.steps.forEach((stepJson) => {
        let stepParams = {
          isNew: false
        };
        
        properties.step.forEach((p) => {
          stepParams[p] = stepJson[p];
        });
        
        stepParams.fields = Ember.A();
        
        if (present(stepJson.fields)) {
          stepJson.fields.forEach((f) => {
            stepParams.fields.pushObject(
              buildObject(f, 'field')
            );
          });
        }

        stepParams.actions = Ember.A();
        
        if (present(stepJson.actions)) {
          stepJson.actions.forEach((a) => {
            stepParams.actions.pushObject(
              buildObject(a, 'action')
            );
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
    props.steps = Ember.A();
  }
  
  return props;
}

export {
  buildStepJson,
  buildJson,
  buildProperties
}