import { default as computed, on, observes } from 'discourse-common/utils/decorators';
import { notEmpty } from "@ember/object/computed";
import { scheduleOnce } from "@ember/runloop";

export default Ember.Component.extend({
  classNameBindings: [':wizard-links', 'type'],
  items: Ember.A(),
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
      Ember.run.bind(this, this.updateItemOrder(itemId, index));
    });
  },

  updateItemOrder(itemId, newIndex) {
    const items = this.get('items');
    const item = items.findBy('id', itemId);
    items.removeObject(item);
    items.insertAt(newIndex, item);
    scheduleOnce('afterRender', this, () => this.applySortable());
  },

  @computed('type')
  header: (type) => `admin.wizard.${type}.header`,

  @computed('items.@each.id', 'current')
  links(items, current) {
    if (!items) return;

    return items.map((item) => {
      if (item) {
        const id = item.get('id');
        const type = this.get('type');
        const label = type === 'action' ? id : (item.get('label') || item.get('title') || id);
        let link = { id, label };

        let classes = 'btn';
        if (current && item.get('id') === current.get('id')) {
          classes += ' btn-primary';
        };

        link['classes'] = classes;

        return link;
      }
    });
  },

  actions: {
    add() {
      const items = this.get('items');
      const type = this.get('type');
      const newId = `${type}_${items.length + 1}`;
      let params = { id: newId, isNew: true };

      if (type === 'step') {
        params['fields'] = Ember.A();
        params['actions'] = Ember.A();
      };

      const newItem = Ember.Object.create(params);
      items.pushObject(newItem);
      this.set('current', newItem);
    },

    change(itemId) {
      const items = this.get('items');
      this.set('current', items.findBy('id', itemId));
    },

    remove(itemId) {
      const items = this.get('items');
      items.removeObject(items.findBy('id', itemId));
      this.set('current', items[items.length - 1]);
    }
  }
});
