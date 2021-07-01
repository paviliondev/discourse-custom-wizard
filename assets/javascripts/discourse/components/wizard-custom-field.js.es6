import { default as discourseComputed } from "discourse-common/utils/decorators";
import { alias, equal, or } from "@ember/object/computed";
import { computed } from "@ember/object";
import { selectKitContent } from "../lib/wizard";
import UndoChanges from "../mixins/undo-changes";
import Component from "@ember/component";
import wizardSchema from "../lib/wizard-schema";

export default Component.extend(UndoChanges, {
  componentType: "field",
  classNameBindings: [":wizard-custom-field", "visible"],
  visible: computed("currentFieldId", function () {
    return this.field.id === this.currentFieldId;
  }),
  isDropdown: equal("field.type", "dropdown"),
  isUpload: equal("field.type", "upload"),
  isCategory: equal("field.type", "category"),
  isGroup: equal("field.type", "group"),
  isTag: equal("field.type", "tag"),
  isText: equal("field.type", "text"),
  isTextarea: equal("field.type", "textarea"),
  isUrl: equal("field.type", "url"),
  isComposer: equal("field.type", "composer"),
  showPrefill: or("isText", "isCategory", "isTag", "isGroup", "isDropdown"),
  showContent: or("isCategory", "isTag", "isGroup", "isDropdown"),
  showLimit: or("isCategory", "isTag"),
  isTextType: or("isText", "isTextarea", "isComposer"),
  isComposerPreview: equal("field.type", "composer_preview"),
  categoryPropertyTypes: selectKitContent(["id", "slug"]),
  showAdvanced: alias("field.type"),
  messageUrl: "https://thepavilion.io/t/2809",

  @discourseComputed("field.type")
  validations(type) {
    const applicableToField = [];

    for (let validation in wizardSchema.field.validations) {
      if (wizardSchema.field.validations[validation]["types"].includes(type)) {
        applicableToField.push(validation);
      }
    }

    return applicableToField;
  },

  @discourseComputed("field.type")
  isDateTime(type) {
    return ["date_time", "date", "time"].indexOf(type) > -1;
  },

  @discourseComputed("field.type")
  messageKey(type) {
    let key = "type";
    if (type) {
      key = "edit";
    }
    return key;
  },

  setupTypeOutput(fieldType, options) {
    const selectionType = {
      category: "category",
      tag: "tag",
      group: "group",
    }[fieldType];

    if (selectionType) {
      options[`${selectionType}Selection`] = "output";
      options.outputDefaultSelection = selectionType;
    }

    return options;
  },

  @discourseComputed("field.type")
  contentOptions(fieldType) {
    let options = {
      wizardFieldSelection: true,
      textSelection: "key,value",
      userFieldSelection: "key,value",
      context: "field",
    };

    options = this.setupTypeOutput(fieldType, options);

    if (this.isDropdown) {
      options.wizardFieldSelection = "key,value";
      options.userFieldOptionsSelection = "output";
      options.textSelection = "key,value,output";
      options.inputTypes = "conditional,association,assignment";
      options.pairConnector = "association";
      options.keyPlaceholder = "admin.wizard.key";
      options.valuePlaceholder = "admin.wizard.value";
    }

    return options;
  },

  @discourseComputed("field.type")
  prefillOptions(fieldType) {
    let options = {
      wizardFieldSelection: true,
      textSelection: true,
      userFieldSelection: "key,value",
      context: "field",
    };

    return this.setupTypeOutput(fieldType, options);
  },

  @discourseComputed("step.index")
  fieldConditionOptions(stepIndex) {
    const options = {
      inputTypes: "validation",
      context: "field",
      textSelection: "value",
      userFieldSelection: true,
      groupSelection: true,
    };

    if (stepIndex > 0) {
      options.wizardFieldSelection = true;
      options.wizardActionSelection = true;
    }

    return options;
  },

  @discourseComputed("step.index")
  fieldIndexOptions(stepIndex) {
    const options = {
      context: "field",
      userFieldSelection: true,
      groupSelection: true,
    };

    if (stepIndex > 0) {
      options.wizardFieldSelection = true;
      options.wizardActionSelection = true;
    }

    return options;
  },

  actions: {
    imageUploadDone(upload) {
      this.set("field.image", upload.url);
    },

    imageUploadDeleted() {
      this.set("field.image", null);
    },
  },
});
