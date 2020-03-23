function generateSelectKitContent(content) {
  return content.map(i => ({id: i, name: i}))
}

function generateName(id) {
  return id.replace(/[_\-]+/g, ' ')
    .toLowerCase()
    .replace(/(^\w|\b\w)/g, (m) => m.toUpperCase())
}

const profileFields = [
  'name',
  'user_avatar',
  'date_of_birth',
  'title',
  'locale',
  'location',
  'website',
  'bio_raw',
  'profile_background',
  'card_background',
  'theme_id'
];

const connectors = [
  {
    id: 'eq',
    name: '='
  },{
    id: 'gt',
    name: '>'
  },{
    id: 'lt',
    name: '<'
  },{
    id: 'gte',
    name: '>='
  },{
    id: 'lte',
    name: '<='
  }
]

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

function newInput(options = {}) {
  let params = { 
    pairs: Ember.A([newPair({ index: 0, pairCount: 1 })])
  }
  
  if (options.hasOutput) {
    params['output'] = '';
    params['output_type'] = 'text';
  }
  
  return Ember.Object.create(params);
}

function newPair(options = {}) {
  console.log('newPair: ', options)
  let params = {
    index: options.index,
    pairCount: options.pairCount,
    key: '',
    key_type: 'text',
    value: '',
    value_type: 'text',
    connector: 'eq'
  }
  
  return Ember.Object.create(params);
}

export {
  generateSelectKitContent,
  profileFields,
  actionTypes,
  generateName,
  connectors,
  newInput,
  newPair
};