import { ajax } from 'discourse/lib/ajax';
import EmberObject from "@ember/object";
import { buildProperties, present, mapped } from '../lib/wizard-json';
import { properties, actionTypeProperties, camelCase, snakeCase } from '../lib/wizard';
import { Promise } from "rsvp";

const jsonStrings = ['api_body'];
const required = ['id', 'steps', 'type'];
const dependent = { after_time: 'after_time_scheduled' }

const CustomWizard = EmberObject.extend({
  save() {
    return new Promise((resolve, reject) => {      
      let json = this.buildJson(this, 'wizard');
      
      if (json.error) {
        reject({ error: json.error });
      }
      
      ajax("/admin/wizards/custom/save", {
        type: 'PUT',
        data: {
          wizard: JSON.stringify(json)
        }
      }).then((result) => {
        if (result.error) {
          reject(result);
        } else {
          resolve(result);
        }
      });
    });
  },

  buildJson(object, type, result = {}) {
    let allowedProperties;
    
    if (type === 'actions') {
      if (!object.type) {
        result.error = {
          type: 'required',
          params: {
            type,
            property: 'type'
          }
        }
        return result;
      }
      
      allowedProperties = actionTypeProperties[object.type];
    } else {
      allowedProperties = properties[type];
    }
        
    for (let property of allowedProperties) {
      let value = object.get(property);
      
      if (required[property] && !value) {
        result.error = {
          type: 'required',
          params: { type, property }
        }
      }
      
      let dependentOn = dependent[property];
      if (dependentOn && value && !object[dependentOn]) {
        result.error = {
          type: 'dependent',
          params: {
            property,
            dependentOn
          }
        }
      }
      
      if (jsonStrings[property]) {
        try {
          value = JSON.parse(value);
        } catch (e) {
          result.error = {
            type: 'invalid',
            params: { type, property }
          }
        }
      }
      
      if (result.error) {
        break;
      }
                  
      if (properties[property]) {
        result[property] = [];
                
        for (let item of value) {
          let itemParams = this.buildJson(item, property);
                    
          if (itemParams.error) {
            result.error = r.error;
            break;
          } else {
            result[property].push(itemParams);
          }
        }
      } else {
        if (mapped(property, type)) {
          value = this.buildMappedJson(value);
        }
        
        if (value !== undefined && value !== null) {
          result[property] = value;
        }
      } 
    };
          
    return result;
  },

  buildMappedJson(inputs) {
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
  },

  remove() {
    return ajax("/admin/wizards/custom/remove", {
      type: 'DELETE',
      data: {
        id: this.get('id')
      }
    }).then(() => this.destroy());
  }
});

CustomWizard.reopenClass({
  all() {
    return ajax("/admin/wizards/custom/all", {
      type: 'GET'
    }).then(result => {
      return result.wizards.map(wizard => {
        return CustomWizard.create(wizard);
      });
    });
  },

  submissions(wizardId) {
    return ajax(`/admin/wizards/submissions/${wizardId}`, {
      type: "GET"
    }).then(result => {
      return result.submissions;
    });
  },

  create(wizardJson = {}) {
    const wizard = this._super.apply(this);
    wizard.setProperties(buildProperties(wizardJson));
    return wizard;
  }
});

export default CustomWizard;
