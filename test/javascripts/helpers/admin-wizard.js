const getWizard = {
  wizard_list: [
    { id: "this_is_testing_wizard", name: "This is testing wizard" },
    { id: "another_wizard", name: "another wizard" },
  ],
  field_types: {
    text: {
      min_length: null,
      max_length: null,
      prefill: null,
      char_counter: null,
      validations: null,
      placeholder: null,
    },
    textarea: {
      min_length: null,
      max_length: null,
      prefill: null,
      char_counter: null,
      placeholder: null,
    },
    composer: {
      min_length: null,
      max_length: null,
      char_counter: null,
      placeholder: null,
    },
    text_only: {},
    composer_preview: { preview_template: null },
    date: { format: "YYYY-MM-DD" },
    time: { format: "HH:mm" },
    date_time: { format: "" },
    number: {},
    checkbox: {},
    url: { min_length: null },
    upload: { file_types: ".jpg,.jpeg,.png" },
    dropdown: { prefill: null, content: null },
    tag: { limit: null, prefill: null, content: null, tag_groups: null },
    category: { limit: 1, property: "id", prefill: null, content: null },
    group: { prefill: null, content: null },
    user_selector: {},
  },
  realtime_validations: {
    similar_topics: {
      types: ["text"],
      component: "similar-topics-validator",
      backend: true,
      required_params: [],
    },
  },
  custom_fields: [
    {
      id: "external",
      klass: "category",
      name: "require_topic_approval",
      type: "boolean",
      serializers: null,
    },
    {
      id: "external",
      klass: "category",
      name: "require_reply_approval",
      type: "boolean",
      serializers: null,
    },
    {
      id: "external",
      klass: "category",
      name: "num_auto_bump_daily",
      type: "integer",
      serializers: null,
    },
    {
      id: "external",
      klass: "category",
      name: "has_chat_enabled",
      type: "boolean",
      serializers: null,
    },
    {
      id: "external",
      klass: "post",
      name: "missing uploads",
      type: "json",
      serializers: null,
    },
    {
      id: "external",
      klass: "post",
      name: "missing uploads ignored",
      type: "boolean",
      serializers: null,
    },
    {
      id: "external",
      klass: "post",
      name: "notice",
      type: "json",
      serializers: null,
    },
    {
      id: "external",
      klass: "post",
      name: "local_dates",
      type: "json",
      serializers: null,
    },
    {
      id: "external",
      klass: "post",
      name: "has_polls",
      type: "boolean",
      serializers: null,
    },
  ],
};
const getUnsubscribedAdminWizards = {
  subscribed: false,
  subscription_type: "none",
  subscription_attributes: {
    wizard: {
      required: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      permitted: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      restart_on_revisit: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    step: {
      condition: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      required_data: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      permitted_params: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    field: {
      condition: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      type: {
        none: [
          "text",
          "textarea",
          "text_only",
          "date",
          "time",
          "date_time",
          "number",
          "checkbox",
          "dropdown",
          "upload",
        ],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      realtime_validations: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    action: {
      type: {
        none: ["create_topic", "update_profile", "open_composer", "route_to"],
        standard: [
          "create_topic",
          "update_profile",
          "open_composer",
          "route_to",
          "send_message",
          "watch_categories",
          "add_to_group",
        ],
        business: ["*"],
        community: ["*"],
      },
    },
    custom_field: {
      klass: {
        none: ["topic", "post"],
        standard: ["topic", "post"],
        business: ["*"],
        community: ["*"],
      },
      type: {
        none: ["string", "boolean", "integer"],
        standard: ["string", "boolean", "integer"],
        business: ["*"],
        community: ["*"],
      },
    },
    api: {
      all: { none: [], standard: [], business: ["*"], community: ["*"] },
    },
  },
  subscription_client_installed: false,
};
const getCustomFields = {
  custom_fields: [
    {
      id: "external",
      klass: "category",
      name: "require_topic_approval",
      type: "boolean",
      serializers: null,
    },
    {
      id: "external",
      klass: "category",
      name: "require_reply_approval",
      type: "boolean",
      serializers: null,
    },
    {
      id: "external",
      klass: "category",
      name: "num_auto_bump_daily",
      type: "integer",
      serializers: null,
    },
    {
      id: "external",
      klass: "category",
      name: "has_chat_enabled",
      type: "boolean",
      serializers: null,
    },
  ],
};
const getWizardTestingLog = {
  wizard: {
    id: "this_is_testing_wizard",
    name: "This is testing wizard",
  },
  logs: [
    {
      date: "2022-12-13T05:32:38.906-04:00",
      action: "create_topic",
      username: "christin",
      message: "success: created topic - id: 119",
      user: {
        id: 55,
        username: "christin",
        name: "Sybil Ratke",
        avatar_template: "",
      },
    },
    {
      date: "2022-12-12T09:41:57.888-04:00",
      action: "create_topic",
      username: "someuser",
      message:
        "error: invalid topic params - title: ; post: creating a text for this text area that is being displayed here.",
      user: {
        id: 1,
        username: "someuser",
        name: null,
        avatar_template: "",
      },
    },
  ],
  total: 2,
};
const getWizardSubmissions = {
  wizard: {
    id: "this_is_testing_wizard",
    name: "This is testing wizard",
  },
  submissions: [
    {
      id: "1",
      fields: {
        step_1_field_1: {
          value:
            "creating a text for this text area that is being displayed here.",
          type: "textarea",
          label: "label field",
        },
      },
      submitted_at: "2022-12-12T09:41:57-04:00",
      user: {
        id: 1,
        username: "someuser",
        name: null,
        avatar_template: "",
      },
    },
  ],
  total: 1,
};
const getAnotherWizardSubmission = {
  wizard: { id: "another_wizard", name: "another wizard" },
  submissions: [
    {
      id: "00925bcd58366d07fb698dc5",
      fields: {
        step_1_field_1: {
          value: "More content here by user",
          type: "text",
          label: "Content to be inserted",
        },
        step_2_field_1: {
          value: "body of the content created by the user",
          type: "textarea",
          label: "Step 2 content",
        },
      },
      submitted_at: "2023-05-10T20:58:11-04:00",
      user: {
        id: 29,
        username: "anotheruser",
        name: null,
        avatar_template: "",
      },
    },
    {
      id: "dc094efcd4873d6da4666c1a",
      fields: {
        step_1_field_1: {
          value: "Title for the content being created",
          type: "text",
          label: "Content to be inserted",
        },
        step_2_field_1: {
          value: "THis is the body of the content that will be created",
          type: "textarea",
          label: "Step 2 content",
        },
      },
      submitted_at: "2023-05-10T20:56:14-04:00",
      user: {
        id: 1,
        username: "someuser",
        name: null,
        avatar_template: "",
      },
    },
  ],
  total: 2,
};
const getBusinessAdminWizard = {
  subscribed: true,
  subscription_type: "business",
  subscription_attributes: {
    wizard: {
      required: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      permitted: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      restart_on_revisit: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    step: {
      condition: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      required_data: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      permitted_params: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    field: {
      condition: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      type: {
        none: [
          "text",
          "textarea",
          "text_only",
          "date",
          "time",
          "date_time",
          "number",
          "checkbox",
          "dropdown",
          "upload",
        ],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      realtime_validations: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    action: {
      type: {
        none: ["create_topic", "update_profile", "open_composer", "route_to"],
        standard: [
          "create_topic",
          "update_profile",
          "open_composer",
          "route_to",
          "send_message",
          "watch_categories",
          "add_to_group",
        ],
        business: ["*"],
        community: ["*"],
      },
    },
    custom_field: {
      klass: {
        none: ["topic", "post"],
        standard: ["topic", "post"],
        business: ["*"],
        community: ["*"],
      },
      type: {
        none: ["string", "boolean", "integer"],
        standard: ["string", "boolean", "integer"],
        business: ["*"],
        community: ["*"],
      },
    },
    api: {
      all: { none: [], standard: [], business: ["*"], community: ["*"] },
    },
  },
  subscription_client_installed: false,
};
const getStandardAdminWizard = {
  subscribed: true,
  subscription_type: "standard",
  subscription_attributes: {
    wizard: {
      required: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      permitted: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      restart_on_revisit: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    step: {
      condition: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      required_data: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      permitted_params: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    field: {
      condition: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      type: {
        none: [
          "text",
          "textarea",
          "text_only",
          "date",
          "time",
          "date_time",
          "number",
          "checkbox",
          "dropdown",
          "upload",
        ],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
      realtime_validations: {
        none: [],
        standard: ["*"],
        business: ["*"],
        community: ["*"],
      },
    },
    action: {
      type: {
        none: ["create_topic", "update_profile", "open_composer", "route_to"],
        standard: [
          "create_topic",
          "update_profile",
          "open_composer",
          "route_to",
          "send_message",
          "watch_categories",
          "add_to_group",
        ],
        business: ["*"],
        community: ["*"],
      },
    },
    custom_field: {
      klass: {
        none: ["topic", "post"],
        standard: ["topic", "post"],
        business: ["*"],
        community: ["*"],
      },
      type: {
        none: ["string", "boolean", "integer"],
        standard: ["string", "boolean", "integer"],
        business: ["*"],
        community: ["*"],
      },
    },
    api: {
      all: { none: [], standard: [], business: ["*"], community: ["*"] },
    },
  },
  subscription_client_installed: false,
};
const getAdminTestingWizard = {
  id: "this_is_testing_wizard",
  name: "This is testing wizard",
  save_submissions: true,
  after_time: false,
  after_time_scheduled: "2022-12-12T13:45:00.000Z",
  prompt_completion: true,
  steps: [
    {
      id: "step_1",
      title: "step 1",
      raw_description: "This is a description for step 1 sads",
      fields: [
        {
          id: "step_1_field_1",
          label: "label field",
          description: "this is the label description",
          type: "textarea",
          placeholder: "insert a textarea text here.",
        },
      ],
      description: "This is a description for step 1 sads",
    },
  ],
  actions: [
    {
      id: "action_1",
      run_after: "wizard_completion",
      type: "create_topic",
      skip_redirect: false,
      post: "step_1_field_1",
      post_builder: false,
      title: [
        {
          type: "assignment",
          output: "Testing title",
          output_type: "text",
          output_connector: "set",
          pairs: [],
        },
      ],
      category: [
        {
          type: "assignment",
          output_type: "category",
          output_connector: "set",
          output: [30],
        },
      ],
    },
  ],
};
const getCreatedWizard = {
  id: "new_wizard_for_testing",
  name: "new wizard for testing",
  save_submissions: true,
  steps: [
    {
      id: "step_1",
      fields: [
        {
          id: "step_1_field_1",
          type: "text",
          validations: {
            similar_topics: {},
          },
        },
      ],
    },
  ],
  actions: [
    {
      id: "action_1",
      run_after: "wizard_completion",
      type: "create_topic",
    },
  ],
};
const getNewApi = {
  name: "new_api",
  title: "new API",
  authorization: {
    auth_type: "basic",
    auth_url: null,
    token_url: null,
    client_id: null,
    client_secret: null,
    authorized: null,
    auth_params: [],
    access_token: null,
    refresh_token: null,
    token_expires_at: null,
    token_refresh_at: null,
    code: null,
    username: "some_username",
    password: "some_password",
  },
  endpoints: [
    {
      id: "8371de",
      name: "endpoint_name",
      method: "POST",
      url: "https://test.api.com",
      content_type: "application/json",
      success_codes: [200, 100],
    },
  ],
  log: [],
};
const putNewApi = {
  success: "OK",
  api: {
    name: "new_api",
    title: "new API",
    authorization: {
      auth_type: "basic",
      auth_url: null,
      token_url: null,
      client_id: null,
      client_secret: null,
      authorized: null,
      auth_params: [],
      access_token: null,
      refresh_token: null,
      token_expires_at: null,
      token_refresh_at: null,
      code: null,
      username: "some_username",
      password: "some_password",
    },
    endpoints: [
      {
        id: "8371de",
        name: "endpoint_name",
        method: "POST",
        url: "https://test.api.com",
        content_type: "application/json",
        success_codes: [200, 100],
      },
    ],
    log: [],
  },
};
export {
  getWizard,
  getUnsubscribedAdminWizards,
  getCustomFields,
  getWizardTestingLog,
  getWizardSubmissions,
  getBusinessAdminWizard,
  getStandardAdminWizard,
  getAdminTestingWizard,
  getCreatedWizard,
  getNewApi,
  putNewApi,
  getAnotherWizardSubmission,
};
