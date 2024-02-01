import { get, set } from "@ember/object";
import { getOwner } from "discourse-common/lib/get-owner";

const wizard = {
  basic: {
    id: null,
    name: null,
    background: null,
    save_submissions: true,
    multiple_submissions: null,
    after_signup: null,
    after_time: null,
    after_time_scheduled: null,
    required: null,
    prompt_completion: null,
    restart_on_revisit: null,
    resume_on_revisit: null,
    theme_id: null,
    permitted: null,
  },
  mapped: ["permitted"],
  required: ["id"],
  dependent: {
    after_time: "after_time_scheduled",
  },
  objectArrays: {
    step: {
      property: "steps",
      required: false,
    },
    action: {
      property: "actions",
      required: false,
    },
  },
};

const step = {
  basic: {
    id: null,
    index: null,
    title: null,
    banner: null,
    banner_upload_id: null,
    raw_description: null,
    required_data: null,
    required_data_message: null,
    permitted_params: null,
    condition: null,
    force_final: false,
  },
  mapped: ["required_data", "permitted_params", "condition", "index"],
  required: ["id"],
  dependent: {},
  objectArrays: {
    field: {
      property: "fields",
      required: false,
    },
  },
};

const field = {
  basic: {
    id: null,
    index: null,
    label: null,
    image: null,
    image_upload_id: null,
    description: null,
    property: null,
    required: null,
    type: null,
    condition: null,
    tag_groups: null,
  },
  types: {},
  mapped: ["prefill", "content", "condition", "index"],
  required: ["id", "type"],
  dependent: {},
  objectArrays: {},
};

const action = {
  basic: {
    id: null,
    run_after: "wizard_completion",
    type: null,
  },
  types: {
    create_topic: {
      title: null,
      post: null,
      post_builder: null,
      post_template: null,
      category: null,
      tags: null,
      visible: null,
      custom_fields: null,
      skip_redirect: null,
      suppress_notifications: null,
      add_event: null,
      add_location: null,
    },
    send_message: {
      title: null,
      post: null,
      post_builder: null,
      post_template: null,
      skip_redirect: null,
      custom_fields: null,
      required: null,
      recipient: null,
      suppress_notifications: null,
    },
    open_composer: {
      title: null,
      post: null,
      post_builder: null,
      post_template: null,
      category: null,
      tags: null,
      custom_fields: null,
    },
    update_profile: {
      profile_updates: null,
      custom_fields: null,
    },
    watch_categories: {
      categories: null,
      notification_level: null,
      mute_remainder: null,
      wizard_user: true,
      usernames: null,
    },
    watch_tags: {
      tags: null,
      notification_level: null,
      wizard_user: true,
      usernames: null,
    },
    send_to_api: {
      api: null,
      api_endpoint: null,
      api_body: null,
    },
    add_to_group: {
      group: null,
    },
    route_to: {
      url: null,
      code: null,
    },
    create_category: {
      name: null,
      slug: null,
      color: null,
      text_color: "FFFFFF",
      parent_category_id: null,
      permissions: null,
      custom_fields: null,
    },
    create_group: {
      name: null,
      full_name: null,
      title: null,
      bio_raw: null,
      owner_usernames: null,
      usernames: null,
      grant_trust_level: null,
      mentionable_level: null,
      messageable_level: null,
      visibility_level: null,
      members_visibility_level: null,
      custom_fields: null,
    },
  },
  mapped: [
    "title",
    "category",
    "tags",
    "visible",
    "custom_fields",
    "required",
    "recipient",
    "profile_updates",
    "group",
    "url",
    "categories",
    "mute_remainder",
    "name",
    "slug",
    "color",
    "text_color",
    "parent_category_id",
    "permissions",
    "full_name",
    "bio_raw",
    "owner_usernames",
    "usernames",
    "grant_trust_level",
    "mentionable_level",
    "messageable_level",
    "visibility_level",
    "members_visibility_level",
    "add_event",
    "add_location",
  ],
  required: ["id", "type"],
  dependent: {},
  objectArrays: {},
};

const filters = {
  allow_guests: {
    field: {
      type: [
        "text",
        "textarea",
        "text_only",
        "date",
        "time",
        "date_time",
        "number",
        "checkbox",
        "url",
        "dropdown",
        "tag",
        "category",
        "group",
        "user_selector",
      ],
    },
    action: {
      type: ["route_to", "send_message"],
    },
  },
};

const custom_field = {
  klass: ["topic", "post", "group", "category"],
  type: ["string", "boolean", "integer", "json"],
};

export function buildFieldTypes(types) {
  wizardSchema.field.types = types;
  wizardSchema.field.type = Object.keys(types);
}

field.type = Object.keys(field.types);
action.type = Object.keys(action.types);

const wizardSchema = {
  wizard,
  step,
  field,
  custom_field,
  action,
  filters,
};

export function buildFieldValidations(validations) {
  wizardSchema.field.validations = validations;
}

export function filterValues(currentWizard, feature, attribute, values = null) {
  values = values || wizardSchema[feature][attribute];

  if (currentWizard && currentWizard.allowGuests) {
    const filteredFeature = wizardSchema.filters.allow_guests[feature];
    if (filteredFeature) {
      const filtered = filteredFeature[attribute];
      if (filtered) {
        values = values.filter((v) => filtered.includes(v));
      }
    }
  }

  return values;
}

const siteSettings = getOwner(this).lookup("service:site-settings");
if (siteSettings.wizard_apis_enabled) {
  wizardSchema.action.types.send_to_api = {
    api: null,
    api_endpoint: null,
    api_body: null,
  };
}

export function setWizardDefaults(obj, itemType) {
  const objSchema = wizardSchema[itemType];
  const basicDefaults = objSchema.basic;

  Object.keys(basicDefaults).forEach((property) => {
    let defaultValue = get(basicDefaults, property);
    if (defaultValue) {
      set(obj, property, defaultValue);
    }
  });

  if (objSchema.types) {
    const typeDefaults = objSchema.types[obj.type];

    if (typeDefaults) {
      Object.keys(typeDefaults).forEach((property) => {
        if (typeDefaults.hasOwnProperty(property)) {
          set(obj, property, get(typeDefaults, property));
        }
      });
    }
  }

  return obj;
}

export default wizardSchema;
