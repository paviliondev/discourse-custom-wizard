import { connectors } from '../lib/custom-wizard';
import { gt } from "@ember/object/computed";

export default Ember.Component.extend({
  classNames: 'pair',
  connectorNone: 'admin.wizard.connector.none',
  connectors: connectors,
  showRemove: gt('pair.index', 0)
})