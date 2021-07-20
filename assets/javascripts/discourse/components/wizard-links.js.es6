import discourseComputed from "discourse-common/utils/decorators";
import { generateName } from "../lib/wizard";
import {
  setWizardDefaults,
  default as wizardSchema,
} from "../lib/wizard-schema";
import { notEmpty } from "@ember/object/computed";
import EmberObject from "@ember/object";
import Component from "@ember/component";
import { A } from "@ember/array";

export default Component.extend({
  classNameBindings: [":wizard-links", "itemType"],
  items: A(),
  anyLinks: notEmpty("links"),

  updateItemOrder(itemId, newIndex) {
    const items = this.items;
    const item = items.findBy("id", itemId);
    items.removeObject(item);
    item.set("index", newIndex);
    items.insertAt(newIndex, item);
  },

  @discourseComputed("itemType")
  header: (itemType) => `admin.wizard.${itemType}.header`,

  @discourseComputed(
    "current",
    "items.@each.id",
    "items.@each.type",
    "items.@each.label",
    "items.@each.title"
  )
  links(current, items) {
    if (!items) {
      return;
    }

    return items.map((item, index) => {
      if (item) {
        let link = {
          id: item.id,
        };

        let label = item.label || item.title || item.id;
        if (this.generateLabels && item.type) {
          label = generateName(item.type);
        }

        link.label = `${label} (${item.id})`;

        let classes = "btn";
        if (current && item.id === current.id) {
          classes += " btn-primary";
        }

        link.classes = classes;
        link.index = index;

        if (index === 0) {
          link.first = true;
        }

        if (index === items.length - 1) {
          link.last = true;
        }

        return link;
      }
    });
  },

  actions: {
    add() {
      const items = this.get("items");
      const itemType = this.itemType;
      let params = setWizardDefaults({}, itemType);

      params.isNew = true;

      let index = 0;
      if (items.length) {
        index = items.length;
      }

      params.index = index;

      let id = `${itemType}_${index + 1}`;
      if (itemType === "field") {
        id = `${this.parentId}_${id}`;
      }

      params.id = id;

      let objectArrays = wizardSchema[itemType].objectArrays;
      if (objectArrays) {
        Object.keys(objectArrays).forEach((objectType) => {
          params[objectArrays[objectType].property] = A();
        });
      }

      const newItem = EmberObject.create(params);
      items.pushObject(newItem);

      this.set("current", newItem);
    },

    back(item) {
      this.updateItemOrder(item.id, item.index - 1);
    },

    forward(item) {
      this.updateItemOrder(item.id, item.index + 1);
    },

    change(itemId) {
      this.set("current", this.items.findBy("id", itemId));
    },

    remove(itemId) {
      const items = this.items;
      let item;
      let index;

      items.forEach((it, ind) => {
        if (it.id === itemId) {
          item = it;
          index = ind;
        }
      });

      let nextIndex;
      if (this.current.id === itemId) {
        nextIndex = index < items.length - 2 ? index + 1 : index - 1;
      }

      items.removeObject(item);

      if (nextIndex) {
        this.set("current", items[nextIndex]);
      }
    },
  },
});
