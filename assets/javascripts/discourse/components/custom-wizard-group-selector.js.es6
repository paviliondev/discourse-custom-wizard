import ComboBox from "select-kit/components/combo-box";
import { computed } from "@ember/object";
import { makeArray } from "discourse-common/lib/helpers";

export default ComboBox.extend({
  content: computed("groups.[]", "field.content.[]", function () {
    const blacklist = ["Administratoren"]; // Gruppe, die nicht ausgewählt werden kann
    const selectedGroups = makeArray(this.field.content); // bereits ausgewählte Gruppen
    return this.groups
      .filter((group) => {
        return blacklist.indexOf(group.name) === -1 && // Gruppe ist nicht in der Blacklist
          (selectedGroups.length === 0 || // wenn keine Gruppen ausgewählt sind
            selectedGroups.indexOf(group.id) > -1); // oder Gruppe bereits ausgewählt wurde
      })
      .map((g) => {
        return {
          id: g.id,
          name: g.full_name ? g.full_name : g.name,
        };
      });
  }),

  didInsertElement() {
    // Setze alle Gruppen als bereits ausgewählt
    this._super(...arguments);
    const selectedGroups = makeArray(this.field.content);
    const allGroups = this.content.map((g) => g.id);
    const unselectedGroups = allGroups.filter((g) => !selectedGroups.includes(g));
    this.updateValue([...selectedGroups, ...unselectedGroups]);
  },
});

