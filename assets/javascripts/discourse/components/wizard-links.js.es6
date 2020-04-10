import { default as discourseComputed, on, observes } from 'discourse-common/utils/decorators';
import { generateName, schema } from '../lib/wizard';
import { notEmpty } from "@ember/object/computed";
import { scheduleOnce, bind } from "@ember/runloop";
import EmberObject from "@ember/object";
import Component from "@ember/component";
import { A } from "@ember/array";

export default Component.extend({
  classNameBindings: [':wizard-links', 'itemType'],
  items: A(),
  anyLinks: notEmpty('links'),

  @on('didInsertElement')
  @observes('links.@each')
  didInsertElement() {
    scheduleOnce('afterRender', () => (this.applySortable()));
  },

  applySortable() {
    $(this.element).find("ul").sortable({tolerance: 'pointer'}).on('sortupdate', (e, ui) => {
      const itemId = ui.item.data('id');
      const index = ui.item.index();
      bind(this, this.updateItemOrder(itemId, index));
    });
  },

  updateItemOrder(itemId, newIndex) {
    const items = this.items;
    const item = items.findBy('id', itemId);
    items.removeObject(item);
    items.insertAt(newIndex, item);
    scheduleOnce('afterRender', this, () => this.applySortable());
  },

  @discourseComputed('itemType')
  header: (itemType) => `admin.wizard.${itemType}.header`,

  @discourseComputed('current', 'items.@each.id', 'items.@each.type', 'items.@each.label', 'items.@each.title')
  links(current, items) {
    if (!items) return;

    return items.map((item) => {
      if (item) {
        let link = {
          id: item.id
        }

        let label = item.label || item.title || item.id;
        if (this.generateLabels && item.type) {
          label = generateName(item.type);
        }
                
        link.label = label;

        let classes = 'btn';
        if (current && item.id === current.id) {
          classes += ' btn-primary';
        };

        link.classes = classes;

        return link;
      }
    });
  },
  
  setDefaults(object, params) {
    Object.keys(object).forEach(property => {
      if (object[property]) {
        params[property] = object[property];
      }
    });
    return params;
  },

  actions: {
    add() {
      const items = this.items;
      const itemType = this.itemType;      
      
      let params = {
        id: `${itemType}_${items.length + 1}`,
        isNew: true
      };
      
      if (schema[itemType].objectArrays) {
        Object.keys(schema[itemType].objectArrays).forEach(objectType => {
          params[objectArrays[objectType].property] = A();
        });
      };
      
      params = this.setDefaults(schema[itemType].basic, params);
      if (schema[itemType].types) {
        params = this.setDefaults(schema[itemType].types[params.type], params);
      }
            
      const newItem = EmberObject.create(params);
      items.pushObject(newItem);
      
      this.set('current', newItem);
    },

    change(itemId) {
      this.set('current', this.items.findBy('id', itemId));
    },

    remove(itemId) {
      const items = this.items;
      items.removeObject(items.findBy('id', itemId));
      this.set('current', items[items.length - 1]);
    }
  }
});
