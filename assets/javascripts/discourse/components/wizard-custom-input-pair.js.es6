import { connectors } from '../lib/custom-wizard';
import { gt, or, alias } from "@ember/object/computed";
import { computed, observes} from "@ember/object"; 

export default Ember.Component.extend({
  classNames: 'pair',
  connectors: connectors,
  hasConnector: or('options.enableConnectors', 'connectorKey'),
  firstPair: gt('pair.index', 0),
  showRemove: alias('firstPair'),
  showJoin: computed('pair.pairCount', function() {
    return this.pair.index < (this.pair.pairCount - 1);
  })
})