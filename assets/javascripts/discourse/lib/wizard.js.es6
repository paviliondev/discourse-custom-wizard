function selectKitContent(content) {
  return content.map(i => ({id: i, name: i}));
}

function generateName(id) {
  return id ? sentenceCase(id) : '';
}

function generateId(name, opts={}) {
  return name ? snakeCase(name) : '';
}

function sentenceCase(string) {
  return string.replace(/[_\-]+/g, ' ')
    .toLowerCase()
    .replace(/(^\w|\b\w)/g, (m) => m.toUpperCase());
}

function snakeCase(string) {
  return string.match(/[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g)
    .map(x => x.toLowerCase())
    .join('_');
}

function camelCase(string) {
  return string.replace(/([-_][a-z])/ig, ($1) => {
    return $1.toUpperCase()
      .replace('-', '')
      .replace('_', '');
  });
}

const profileFields = [
  'name',
  'email',
  'avatar',
  'date_of_birth',
  'title',
  'profile_background',
  'card_background',
  'locale',
  'location',
  'website',
  'bio_raw',
  'trust_level'
];

const wizardProperties = [
  'id',
  'name',
  'background',
  'save_submissions',
  'multiple_submissions',
  'after_signup',
  'after_time',
  'after_time_scheduled',
  'required',
  'prompt_completion',
  'restart_on_revisit',
  'theme_id',
  'permitted',
  'steps',
  'actions'
];

const stepProperties = [
  'id',
  'title',
  'key',
  'banner',
  'raw_description',
  'required_data',
  'required_data_message',
  'permitted_params',
  'fields'
]

const fieldProperties = [
  'id',
  'label',
  'key',
  'image',
  'description',
  'type',
  'required',
  'min_length',
  'file_types',
  'property',
  'limit',
  'prefill',
  'content'
]

const actionProperties = [
  'id',
  'type',
  'run_after',
  'title',
  'post',
  'post_builder',
  'post_template',
  'category',
  'tags',
  'skip_redirect',
  'custom_fields',
  'required',
  'recipient',
  'profile_updates',
  'group',
  'url',
  'code',
  'api',
  'api_endpoint',
  'api_body'
]

const properties = {
  wizard: wizardProperties,
  steps: stepProperties,
  fields: fieldProperties,
  actions: actionProperties
}

const actionTypeProperties = {
  create_topic: [
    'id',
    'type',
    'run_after',
    'title',
    'post',
    'post_builder',
    'post_template',
    'category',
    'tags',
    'skip_redirect',
    'custom_fields'
  ],
  send_message: [
    'id',
    'type',
    'run_after',
    'title',
    'post',
    'post_builder',
    'post_template',
    'skip_redirect',
    'custom_fields',
    'required',
    'recipient'
  ],
  open_composer: [
    'id',
    'type',
    'run_after',
    'title',
    'post',
    'post_builder',
    'post_template',
    'category',
    'tags',
    'custom_fields'
  ],
  update_profile: [
    'id',
    'type',
    'run_after',
    'profile_updates',
    'custom_fields'
  ],
  add_to_group: [
    'id',
    'type',
    'run_after',
    'group'
  ],
  route_to: [
    'id',
    'type',
    'run_after',
    'url',
    'code'
  ],
  send_to_api: [
    'id',
    'type',
    'run_after',
    'api',
    'api_endpoint',
    'api_body'
  ]
}

const mappedProperties = {
  wizard: [
    'permitted'
  ],
  steps: [
    'required_data',
    'permitted_params'
  ],
  fields: [
    'prefill',
    'content'
  ],
  actions: [
    'title',
    'category',
    'tags',
    'custom_fields',
    'required',
    'recipient',
    'profile_updates',
    'group'
  ]
}

const defaultProperties = {
  action: {
    run_after: 'wizard_completion'
  }
}

const advancedFieldTypes = [
  'category',
  'tag',
  'group',
  'dropdown'
]

const advancedFieldProperties = [
  'prefill',
  'content'
]

const actionTypes = [
  'create_topic',
  'update_profile',
  'send_message',
  'send_to_api',
  'add_to_group',
  'route_to',
  'open_composer'
].filter(function(type) {
  return Discourse.SiteSettings.wizard_api_features || type !== 'send_to_api'; 
});

const advancedProperties = {
  steps: [
    'required_data',
    'permitted_params'
  ],
  fields: advancedFieldTypes.reduce(
    function(map, type) {
      map[type] = advancedFieldProperties;
      if (type === 'category') {
        map[type].push('property');
      }
      return map;
    }, {}
  ),
  actions: actionTypes.reduce(
    function(map, type) {
      if (type === 'route_to') {
        map[type] = ['code'];
      } else if (['create_topic', 'send_message', 'open_composer', 'update_profile'].indexOf(type) > -1) {
        map[type] = ['custom_fields'];
      } else if (['create_topic', 'send_message'].indexOf(type) > -1) {
        map[type].push('skip_redirect');
      } else if (type === 'send_message') {
        map[type].push('required');
      }
      return map;
    }, {}
  )
}

export {
  selectKitContent,
  generateName,
  generateId,
  camelCase,
  snakeCase,
  properties,
  wizardProperties,
  mappedProperties,
  profileFields,
  advancedProperties,
  actionTypes,
  actionTypeProperties,
  defaultProperties
};