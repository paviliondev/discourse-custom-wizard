function generateSelectKitContent(content) {
  return content.map(i => ({id: i, name: i}))
}

function generateName(id) {
  return id.replace(/[_\-]+/g, ' ')
    .toLowerCase()
    .replace(/(^\w|\b\w)/g, (m) => m.toUpperCase())
}

function generateId(name) {
  return name.replace(/[^\w ]/g, '')
    .replace(/ /g,"_")
    .toLowerCase();
}

const profileFields = [
  'name',
  'username',
  'email',
  'date_of_birth',
  'title',
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
  'permitted'
];

const stepProperties = [
  'id',
  'title',
  'key',
  'banner',
  'raw_description',
  'required_data',
  'required_data_message',
  'permitted_params'
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
  'content',
]

const actionProperties = [
  'id',
  'type',
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
  step: stepProperties,
  field: fieldProperties,
  action: actionProperties
}

const mappedProperties = {
  wizard: [
    'permitted'
  ],
  step: [
    'required_data',
    'permitted_params'
  ],
  field: [
    'choices',
    'prefill',
    'content'
  ],
  action: [
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

const actionTypes = [
  'create_topic',
  'update_profile',
  'create_topic',
  'update_profile',
  'send_message',
  'send_to_api',
  'add_to_group',
  'route_to',
  'open_composer'
];

export {
  generateSelectKitContent,
  generateName,
  generateId,
  properties,
  wizardProperties,
  mappedProperties,
  profileFields,
  actionTypes
};