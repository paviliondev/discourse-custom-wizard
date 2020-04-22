import { default as discourseComputed, on, observes } from 'discourse-common/utils/decorators';
import { generateName } from '../lib/wizard';
import { default as wizardSchema, setWizardDefaults } from '../lib/wizard-schema';
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
  @observes('links.[]')
  setupSortable() {
    scheduleOnce('afterRender', () => (this.applySortable()));
  },

  applySortable() {
    $(this.element).find(".link-list")
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
      const items = this.get('items');
      const itemType = this.itemType;
      let params = setWizardDefaults({}, itemType);
      
      params.isNew = true;
      
      let next = 1;
            
      if (items.length) {
        next = Math.max.apply(Math, items.map((i) => {
          let parts = i.id.split('_');
          let lastPart = parts[parts.length - 1];
          return isNaN(lastPart) ? 0 : lastPart;
        })) + 1;
      }
            
      let id = `${itemType}_${next}`;
      
      if (itemType === 'field') {
        id = `${this.parentId}_${id}`;
      }
    
      params.id = id;
      
      let objectArrays = wizardSchema[itemType].objectArrays;
      if (objectArrays) {
        Object.keys(objectArrays).forEach(objectType => {
          params[objectArrays[objectType].property] = A();
        });
      };
          
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
