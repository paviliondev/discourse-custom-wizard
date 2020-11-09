import { ajax } from 'discourse/lib/ajax';
import EmberObject from "@ember/object";
import { buildProperties, present, mapped } from '../lib/wizard-json';
import { listProperties, camelCase, snakeCase } from '../lib/wizard';
import wizardSchema from '../lib/wizard-schema';
import { Promise } from "rsvp";
import { popupAjaxError } from 'discourse/lib/ajax-error';

const CustomWizard = EmberObject.extend({
  save(opts) {
    return new Promise((resolve, reject) => {      
      let wizard = this.buildJson(this, 'wizard');
      
      if (wizard.error) {
        reject(wizard);
      }
      
      let data = {
        wizard
      };
      
      if (opts.create) {
        data.create = true;
      }
            
      ajax(`/admin/wizards/wizard/${wizard.id}`, {
        type: 'PUT',
        contentType: "application/json",
        data: JSON.stringify(data)
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
    let objectType = object.type || null;
    
    if (wizardSchema[type].types) {
      if (!objectType) {
        result.error = {
          type: 'required',
          params: { type, property: 'type' }
        }
        return result;
      }
    }
            
    for (let property of listProperties(type, { objectType })) {
      let value = object.get(property);
      
      result = this.validateValue(property, value, object, type, result);
      
      if (result.error) {
        break;
      }
        
      if (mapped(property, type)) {
        value = this.buildMappedJson(value);
      }
            
      if (value !== undefined && value !== null) {
        result[property] = value;
      }
    };
    
    if (!result.error) {
      for (let arrayObjectType of Object.keys(wizardSchema[type].objectArrays)) {
        let arraySchema = wizardSchema[type].objectArrays[arrayObjectType];
        let objectArray = object.get(arraySchema.property);
                
        if (arraySchema.required && !present(objectArray)) {
          result.error = {
            type: 'required',
            params: { type, property: arraySchema.property }
          }
          break;
        }

        result[arraySchema.property] = [];
                
        for (let item of objectArray) {
          let itemProps = this.buildJson(item, arrayObjectType);
                    
          if (itemProps.error) {
            result.error = itemProps.error;
            break;
          } else {
            result[arraySchema.property].push(itemProps);
          }
        }
      };
    }
          
    return result;
  },
  
  validateValue(property, value, object, type, result) {
    if (wizardSchema[type].required.indexOf(property) > -1 && !value) {
      result.error = {
        type: 'required',
        params: { type, property }
      }
    }
    
    let dependent = wizardSchema[type].dependent[property];
    if (dependent && value && !object[dependent]) {
      result.error = {
        type: 'dependent',
        params: { property, dependent }
      }
    }
    
    if (property === 'api_body') {
      try {
        value = JSON.parse(value);
      } catch (e) {
        result.error = {
          type: 'invalid',
          params: { type, property }
        }
      }
    }
    
    return result;
  },

  buildMappedJson(inputs) {
    if (!inputs || !inputs.length) return false;
    
    let result = [];
      
    inputs.forEach(inpt => {
      let input = {
        type: inpt.type,
      };
      
      if (inpt.connector) {
        input.connector = inpt.connector;
      }
          
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
    return ajax(`/admin/wizards/wizard/${this.id}`, {
      type: 'DELETE'
    }).then(() => this.destroy()).catch(popupAjaxError);
  }
});

CustomWizard.reopenClass({
  all() {
    return ajax("/admin/wizards/wizard", {
      type: 'GET'
    }).then(result => {
      return result.wizard_list;
    }).catch(popupAjaxError);
  },

  submissions(wizardId) {
    return ajax(`/admin/wizards/submissions/${wizardId}`, {
      type: "GET"
    }).catch(popupAjaxError);
  },

  create(wizardJson = {}) {
    const wizard = this._super.apply(this);
    wizard.setProperties(buildProperties(wizardJson));
    return wizard;
  }
});

export default CustomWizard;
