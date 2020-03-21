import { connectors } from '../lib/custom-wizard';
import { gt } from "@ember/object/computed";

export default Ember.Component.extend({
  classNames: 'pair',
  connectorNone: 'admin.wizard.connector.none',
  connectors: connectors.map(c => ({ id: c, name: I18n.t(`admin.wizard.connector.${c}`) })),
  showRemove: gt('pair.index', 0)
})