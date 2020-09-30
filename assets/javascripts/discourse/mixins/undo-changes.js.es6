import { listProperties } from '../lib/wizard';
import { default as wizardSchema } from '../lib/wizard-schema';
import { set, get } from "@ember/object";
import Mixin from "@ember/object/mixin";
import { observes } from 'discourse-common/utils/decorators';
import { deepEqual } from 'discourse-common/lib/object';

export default Mixin.create({
  didInsertElement() {
    this._super(...arguments);
    this.setupObservers();

    const obj = this.get(this.componentType);

    this.setProperties({
      originalObject: JSON.parse(JSON.stringify(obj)),
      undoIcon: obj.isNew ? 'times' : 'undo',
      undoKey: `admin.wizard.${obj.isNew ? 'clear' : 'undo'}`
    })
  },

  willDestroyElement() {
    this._super(...arguments);
    this.removeObservers();
  },

  removeObservers(objType=null) {
    const componentType = this.componentType;
    const obj = this.get(componentType);

    let opts = {
      objectType: objType || obj.type
    }

    listProperties(componentType, opts).forEach(property => {
      obj.removeObserver(property, this, this.toggleUndo);
    });
  },

  setupObservers(objType=null) {
    const componentType = this.componentType;
    const obj = this.get(componentType);

    let opts = {
      objectType: objType || obj.type
    }

    listProperties(componentType, opts).forEach(property => {
      obj.addObserver(property, this, this.toggleUndo);
    });
  },

  revertToOriginal(revertBasic=false) {
    const original = JSON.parse(JSON.stringify(this.originalObject));
    const componentType = this.componentType;
    const obj = this.get(componentType);
    const objSchema = wizardSchema[componentType];
    const basicDefaults = objSchema.basic;

    if (revertBasic) {
      Object.keys(basicDefaults).forEach(property => {
        let value;

        if (original.hasOwnProperty(property)) {
          value = get(original, property);
        } else if (basicDefaults.hasOwnProperty(property)) {
          value = get(basicDefaults, property);
        }

        set(obj, property, value);
      });
    }

    if (objSchema.types && obj.type) {
      let typeDefaults = objSchema.types[obj.type];

      Object.keys(typeDefaults).forEach(property => {
        let value;

        if (original.type === obj.type && original.hasOwnProperty(property)) {
          value = get(original, property);
        } else if (typeDefaults.hasOwnProperty(property)) {
          value = get(typeDefaults, property);
        }

        set(obj, property, value);
      });
    }
  },

  toggleUndo() {
    const current = this.get(this.componentType);
    const original = this.originalObject;
    this.set('showUndo', !deepEqual(current, original));
  },

  actions: {
    undoChanges() {
      const componentType = this.componentType;
      const original = this.get('originalObject');
      const obj = this.get(componentType);

      this.removeObservers(obj.type);
      this.revertToOriginal(true);
      this.set('showUndo', false);
      this.setupObservers(this.get(componentType).type);
    },

    changeType(type) {
      const componentType = this.componentType;
      const original = this.get('originalObject');
      const obj = this.get(componentType);

      this.removeObservers(obj.type);
      obj.set('type', type);
      this.revertToOriginal();
      this.set('showUndo', type !== original.type);
      this.setupObservers(type);
    },

    mappedFieldUpdated(property, mappedComponent, type) {
      const obj = this.get(this.componentType);
      obj.notifyPropertyChange(property);
    }
  }
})
