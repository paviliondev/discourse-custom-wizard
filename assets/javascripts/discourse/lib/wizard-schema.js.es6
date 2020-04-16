import { set } from "@ember/object";

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
    theme_id: null,
    permitted: null
  },
  mapped: [
    'permitted'
  ],
  advanced: [
    'restart_on_revisit',
  ],
  required: [
    'id',
  ],
  dependent: {
    after_time: 'after_time_scheduled'
  },
  objectArrays: {
    step: {
      property: 'steps',
      required: false
    },
    action: {
      property: 'actions',
      required: false
    }
  }
};

const step = {
  basic: {
    id: null,
    title: null,
    key: null,
    banner: null,
    raw_description: null,
    required_data: null,
    required_data_message: null,
    permitted_params: null
  },
  mapped: [
    'required_data',
    'permitted_params'
  ],
  advanced: [
    'required_data',
    'permitted_params'
  ],
  required: [
    'id'
  ],
  dependent: {
  },
  objectArrays: {
    field: {
      property: 'fields',
      required: false
    }
  }
}

const field = {
  basic: {
    id: null,
    label: null,
    image: null,
    description: null,
    required: null,
    key: null,
    type: null
  },
  types: {},
  mapped: [
    'prefill',
    'content'
  ],
  advanced: [
    'property',
    'key'
  ],
  required: [
    'id',
    'type'
  ],
  dependent: {
  },
  objectArrays: {
  }
}

const action = {
  basic: {
    id: null,
    run_after: 'wizard_completion',
    type: null
  },
  types: {
    create_topic: {
      title: null,
      post: null,
      post_builder: null,
      post_template: null,
      category: null,
      tags: null,
      custom_fields: null,
      skip_redirect: null
    },
    send_message: {
      title: null,
      post: null,
      post_builder: null,
      post_template: null,
      skip_redirect: null,
      custom_fields: null,
      required: null,
      recipient: null
    },
    open_composer: {
      title: null,
      post: null,
      post_builder: null,
      post_template: null,
      category: null,
      tags: null,
      custom_fields: null
    },
    update_profile: {
      profile_updates: null,
      custom_fields: null
    },
    add_to_group: {
      group: null
    },
    route_to: {
      url: null,
      code: null
    }
  },
  mapped: [
    'title',
    'category',
    'tags',
    'custom_fields',
    'required',
    'recipient',
    'profile_updates',
    'group'
  ],
  advanced: [
    'code',
    'custom_fields',
    'skip_redirect',
    'required'
  ],
  required: [
    'id',
    'type'
  ],
  dependent: {
  },
  objectArrays: {
  }
}

const wizardSchema = {
  wizard,
  step,
  field,
  action
}

export function buildFieldTypes(types) {
  wizardSchema.field.types = types;
}

if (Discourse.SiteSettings.wizard_apis_enabled) {
  wizardSchema.action.types.send_to_api = {
    api: null,
    api_endpoint: null,
    api_body: null
  }
}

export function setSchemaDefaults(obj, objType) {
  let objSchema = wizardSchema[objType];
  let basicDefaults = objSchema.basic;
    
  Object.keys(basicDefaults).forEach(property => {  
    if (basicDefaults[property]) {
      set(obj, property, basicDefaults[property]);
    }
  });
  
  if (objSchema.types && obj.type) {
    let typeDefaults = objSchema.types[obj.type];
    
    Object.keys(typeDefaults).forEach(property => {
      if (typeDefaults.hasOwnProperty(property)) {
        set(obj, property, typeDefaults[property]);
      }
    });
  }
}

export default wizardSchema;