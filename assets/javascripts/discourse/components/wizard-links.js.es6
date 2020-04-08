import { default as discourseComputed, on, observes } from 'discourse-common/utils/decorators';
import { generateName, defaultProperties } from '../lib/wizard';
import { notEmpty } from "@ember/object/computed";
import { scheduleOnce, bind } from "@ember/runloop";
import EmberObject from "@ember/object";
import Component from "@ember/component";
import { A } from "@ember/array";

export default Component.extend({
  classNameBindings: [':wizard-links', 'type'],
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

  @discourseComputed('type')
  header: (type) => `admin.wizard.${type}.header`,

  @discourseComputed('current', 'items.@each.id', 'items.@each.type')
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

  actions: {
    add() {
      const items = this.items;
      const type = this.type;
      const newId = `${type}_${items.length + 1}`;
      
      let params = {
        id: newId,
        isNew: true
      };

      if (type === 'step') {
        params.fields = A();
      };
      
      if (defaultProperties[type]) {
        Object.keys(defaultProperties[type]).forEach(key => {
          params[key] = defaultProperties[type][key];
        });
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
