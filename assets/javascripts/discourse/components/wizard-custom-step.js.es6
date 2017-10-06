import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-step',
  currentField: null,
  currentAction: null,

  @on('init')
  @observes('step.id')
  setup() {
    this._super(...arguments);
    const fields = this.get('step.fields');
    const actions = this.get('step.actions');
    this.set('currentField', fields[0]);
    this.set('currentAction', actions[0]);
  },

  @computed('step.fields.[]', 'currentField')
  fieldLinks(fields, current) {
    return fields.map((f) => {
      if (f) {
        let link = {
          id: f.get('id'),
          label: f.get('label')
        };

        let classes = 'btn';
        if (current && f.get('id') === current.get('id')) {
          classes += ' btn-primary';
        };

        link['classes'] = classes;

        return link;
      }
    });
  },

  @computed('step.actions.[]', 'currentAction')
  actionLinks(actions, current) {
    return actions.map((a) => {
      if (a) {
        let link = {
          id: a.get('id'),
          label: a.get('label')
        };

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
      const newNum = fields.length + 1;
      const field = Ember.Object.create({
        id: `field-${newNum}`, label: `Field ${newNum}`
      });
      fields.pushObject(field);
      this.set('currentField', field);
    },

    addAction() {
      const actions = this.get('step.actions');
      const newNum = actions.length + 1;
      const action = Ember.Object.create({
        id: `action-${newNum}`, label: `Action ${newNum}`
      });
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
