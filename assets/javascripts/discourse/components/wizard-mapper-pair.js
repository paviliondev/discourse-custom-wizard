import Component from "@ember/component";
import { computed } from "@ember/object";
import { alias, gt } from "@ember/object/computed";
import { connectorContent } from "../lib/wizard-mapper";

export default Component.extend({
  classNameBindings: [":mapper-pair", "hasConnector::no-connector"],
  firstPair: gt("pair.index", 0),
  showRemove: alias("firstPair"),
  showJoin: computed("pair.pairCount", function () {
    return this.pair.index < this.pair.pairCount - 1;
  }),
  connectors: computed(function () {
    return connectorContent("pair", this.inputType, this.options);
  }),
});
