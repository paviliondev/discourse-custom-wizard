import { default as discourseComputed, on, observes } from 'discourse-common/utils/decorators';
import { generateName } from '../lib/wizard';
import { default as wizardSchema, setSchemaDefaults } from '../lib/wizard-schema';
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
    $(this.element).find("ul")
      .sortable({ tolerance: 'pointer' })
      .on('sortupdate', (e, ui) => {
        this.updateItemOrder(ui.item.data('id'), ui.item.index());
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
                
        link.label = `${label} (${item.id})`;

        let classes = 'btn';
        if (current && item.id === current.id) {
          classes += ' btn-primary';
        };

        link.classes = classes;

        return link;
      }
    });
  },

  actions: {
    add() {
      const items = this.items;
      const itemType = this.itemType;
      let next = 1;
      
      if (items.length) {
        next =  Math.max.apply(Math, items.map((i) => (i.id.split('_')[1]))) + 1;
      }
            
      let params = {
        id: `${itemType}_${next}`,
        isNew: true
      };
      
      let objectArrays = wizardSchema[itemType].objectArrays;
      if (objectArrays) {
        Object.keys(objectArrays).forEach(objectType => {
          params[objectArrays[objectType].property] = A();
        });
      };
      
      setSchemaDefaults(params, itemType);
            
      const newItem = EmberObject.create(params);
      items.pushObject(newItem);
      
      this.set('current', newItem);
    },

    change(itemId) {
      this.set('current', this.items.findBy('id', itemId));
    },

    remove(itemId) {
      const items = this.items;
      let item;
      let index;
            
      items.forEach((it, ind) => {
        if (it.id === itemId) {
          item = it;
          index = ind;
        }
      });
      
      let nextIndex;
      if (this.current.id === itemId) {
        nextIndex = index < (items.length-2) ? (index+1) : (index-1);
      }
      
      items.removeObject(item);
      
      if (nextIndex) {
        this.set('current', items[nextIndex]);
      }
    }
  }
});
