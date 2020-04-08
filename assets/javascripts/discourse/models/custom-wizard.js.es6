import { ajax } from 'discourse/lib/ajax';
import EmberObject from "@ember/object";
import { buildJson, buildProperties, present } from '../lib/wizard-json';
import { properties, arrays, camelCase, snakeCase } from '../lib/wizard';
import { Promise } from "rsvp";

const jsonStrings = ['api_body'];
const required = ['id', 'steps', 'type'];
const dependent = { after_time: 'after_time_scheduled' }

const CustomWizard = EmberObject.extend({
  save() {
    return new Promise((resolve, reject) => {
      let json = this.buildJson(this, 'wizard');
      
      if (json.error) {
        reject({ eror: json.error });
      }
      
      ajax("/admin/wizards/custom/save", {
        type: 'PUT',
        data: {
          wizard: JSON.stringify(wizardJson)
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
    for (let property of properties[type]) {
      let value = object.get(property);
      
      if (objectArrays[type]) {
        result[property] = [];
        
        for (let obj of value) {
          let obj = this.buildJson(value, property, result);
          
          if (obj.error) {
            result.error = r.error;
            break;
          } else {
            result[property].push(obj);
          }
        }
      }
      
      if (required[property] && !value) {
        result.error = 'required'
        result.errorParams = { type, property };
      }
      
      if (dependent[property] && !properties[type][dependent[property]]) {
        result.error = 'dependent';
        result.errorParams = {
          dependentProperty: properties[type][dependent[property]],
          property
        }
      }
      
      if (jsonStrings[property]) {
        try {
          value = JSON.parse(value);
        } catch (e) {
          result.error = 'invalid';
          result.errorParams = { property };
        }
      }
      
      if (mapped(property, type)) {
        value = this.buildMappedJson(value);
      }
      
      if (result.error) {
        break;
      } else if (value) {
        result[property] = value;
      }
    });
      
    return result;
  }

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
