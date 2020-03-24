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

const selectionTypes = [
  'text',
  'wizardField',
  'userField',
  'group',
  'category',
  'tag'
]

const inputTypes = [
  'pair',
  'conditional',
  'assignment'
]

function defaultInputType(options = {}) {
  return options.hasOutput ? 'conditional' : 'pair';
}

function defaultSelectionType(inputType, options = {}) {
  const textDisabled = options.textDisabled;
  let type = 'text';
  
  if (textDisabled === true || 
      ((typeof textDisabled == 'string') && textDisabled.indexOf(inputType) > -1)) {
    
    for (let t of selectionTypes) {
      let inputTypes = options[`${t}Selection`];
      
      if (inputTypes === true || 
          ((typeof inputTypes == 'string') && inputTypes.indexOf(inputType) > -1)) {
        
        type = t;
        break;
      }
    }
  }
  
  return type;
}

function newInput(options = {}) {
  let params = {
    type: defaultInputType(options),
    pairs: Ember.A([newPair({ index: 0, pairCount: 1 })])
  }
  
  if (options.hasOutput) {
    params['output_type'] = defaultSelectionType('output', options);
  }
  
  return Ember.Object.create(params);
}

function newPair(options = {}) {
  let params = {
    index: options.index,
    pairCount: options.pairCount,
    key: '',
    key_type: defaultSelectionType('text', options),
    value: '',
    value_type: defaultSelectionType('text', options),
    connector: 'eq'
  }
  
  return Ember.Object.create(params);
}

export {
  generateSelectKitContent,
  profileFields,
  actionTypes,
  generateName,
  defaultInputType,
  defaultSelectionType,
  connectors,
  newInput,
  newPair
};