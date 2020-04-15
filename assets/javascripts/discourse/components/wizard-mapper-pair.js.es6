import { connectorContent } from '../lib/wizard-mapper';
import { gt, or, alias } from "@ember/object/computed";
import { computed, observes } from "@ember/object"; 
import Component from "@ember/component";

export default Component.extend({
  classNameBindings: [':mapper-pair', 'hasConnector::no-connector'],
  firstPair: gt('pair.index', 0),
  showRemove: alias('firstPair'),
  showJoin: computed('pair.pairCount', function() { return this.pair.index < (this.pair.pairCount - 1) }),
  connectors: computed(function() { return connectorContent('pair', this.inputType, this.options) })
});