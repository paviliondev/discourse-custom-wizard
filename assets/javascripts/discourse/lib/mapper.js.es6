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

// Inputs

const selectableInputTypes = [
  'conditional',
  'assignment'
]

function defaultInputType(options = {}) {
  if (!options.hasOutput) return 'pair';
  if (!options.inputTypes) return selectableInputTypes[0];
  return options.inputTypes.split(',')[0];
}

function mapInputTypes(types) {
  return types.map(function(type) {
    return {
      id: type, 
      name: I18n.t(`admin.wizard.input.${type}.name`) 
    };
  });
}

function inputTypesContent(options = {}) {
  return options.inputTypes ?
    mapInputTypes(options.inputTypes.split(',')) :
    mapInputTypes(selectableInputTypes);
}

// Connectors

const connectors = {
  output: [
    'then',
    'set',
  ],
  pair: [
    'equal',
    'greater',
    'less',
    'greater_or_equal',
    'less_or_equal'
  ]
}

function connectorItem(connector) {
  return {
    id: connector, 
    name: I18n.t(`admin.wizard.connector.${connector}`) 
  };
}

function defaultConnector(connectorType, inputType, opts = {}) {
  if (opts[`${connectorType}Connector`]) return opts[`${connectorType}Connector`];  
  if (inputType === 'assignment') return 'set';
  return connectorType === 'output' ? 'then' : 'equal';
}

function connectorContent(connectorType, inputType, opts) {
  let connector = opts[`${connectorType}Connector`] || defaultConnector(connectorType, inputType, opts);
  if (connector) return [connectorItem(connector)];
  
  return connectors[connectorType].map(function(connector) {
    return connectorItem(connector);
  });
}

// Selectors

const selectionTypes = [
  'text',
  'wizard',
  'user',
  'group',
  'category',
  'tag'
]

function defaultSelectionType(inputType, options = {}) {
  if (options[`${inputType}DefaultSelection`]) {
    return options[`${inputType}DefaultSelection`];
  }
    
  let type = selectionTypes[0];
  
  for (let t of selectionTypes) {
    let inputTypes = options[`${t}Selection`];
                
    if (inputTypes === true || 
        ((typeof inputTypes === 'string') &&
         inputTypes.split(',').indexOf(inputType) > -1)) {
      type = t;
      break;
    }
  }
    
  return type;
}

// items

function newPair(inputType, options = {}) {
  let params = {
    index: options.index,
    pairCount: options.pairCount,
    key: '',
    key_type: defaultSelectionType('key', options),
    value: '',
    value_type: defaultSelectionType('value', options),
    connector: defaultConnector('pair', inputType, options)
  }
    
  return Ember.Object.create(params);
}

function newInput(options = {}) {
  const inputType = defaultInputType(options);
  
  let params = {
    type: inputType,
    pairs: Ember.A(
      [
        newPair(
          inputType,
          Object.assign({},
            options,
            { index: 0, pairCount: 1 }
          )
        )
      ]
    )
  }
  
  if (options.hasOutput) {
    params['output_type'] = defaultSelectionType('output', options);
    params['connector'] = defaultConnector('output', inputType, options);
  }
    
  return Ember.Object.create(params);
}

export {
  mappedProperties,
  defaultInputType,
  defaultSelectionType,
  connectorContent,
  inputTypesContent,
  newInput,
  newPair,
}