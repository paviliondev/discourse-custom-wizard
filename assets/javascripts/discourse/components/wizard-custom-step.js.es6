import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-step',
  currentField: null,
  currentAction: null,

  @on('init')
  @observes('step')
  setCurrent() {
    this.set('existingId', this.get('step.id'));
    const fields = this.get('step.fields') || [];
    const actions = this.get('step.actions') || [];
    this.set('currentField', fields[0]);
    this.set('currentAction', actions[0]);
  },

  @computed('step.fields.@each.id', 'currentField')
  fieldLinks(fields, current) {
    if (!fields) return;

    return fields.map((f) => {
      if (f) {
        const id = f.get('id');
        const label = f.get('label');

        let link = { id, label: label || id || 'new' };

        let classes = 'btn';
        if (current && f.get('id') === current.get('id')) {
          classes += ' btn-primary';
        };

        link['classes'] = classes;

        return link;
      }
    });
  },

  @computed('step.actions.@each.id', 'currentAction')
  actionLinks(actions, current) {
    if (!actions) return;

    return actions.map((a) => {
      if (a) {
        const id = a.get('id');
        const label = a.get('label');

        let link = { id, label: label || id || 'new' };

        let classes = 'btn';
        if (current && a.get('id') === current.get('id')) {
          classes += ' btn-primary';
        };

        link['classes'] = classes;

        return link;
      }
    });
  },

  actions: {
    addField() {
      const fields = this.get('step.fields');
      const field = Ember.Object.create();
      fields.pushObject(field);
      this.set('currentField', field);
    },

    addAction() {
      const actions = this.get('step.actions');
      const action = Ember.Object.create();
      actions.pushObject(action);
      this.set('currentAction', action);
    },

    removeField(fieldId) {
      const fields = this.get('step.fields');
      fields.removeObject(fields.findBy('id', fieldId));
      this.set('currentField', fields[fields.length - 1]);
    },

    removeAction(actionId) {
      const actions = this.get('step.actions');
      actions.removeObject(actions.findBy('id', actionId));
      this.set('currentAction', actions[actions.length - 1]);
    },

    changeField(fieldId) {
      const fields = this.get('step.fields');
      this.set('currentField', fields.findBy('id', fieldId));
    },

    changeAction(actionId) {
      const actions = this.get('step.actions');
      this.set('currentAction', actions.findBy('id', actionId));
    }
  }
});
