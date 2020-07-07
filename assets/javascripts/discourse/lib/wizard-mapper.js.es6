import EmberObject from "@ember/object";
import { A } from "@ember/array";
import I18n from "I18n";

// Inputs

function defaultInputType(options = {}) {
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

// connectorTypes

const connectors = {
  pair: [
    'equal',
    'greater',
    'less',
    'greater_or_equal',
    'less_or_equal',
    'regex',
    'is'
  ],
  output: [
    'then',
    'set',
  ],
}

function defaultConnector(connectorType, inputType, options={}) {
  if (connectorType === 'input') {
    return defaultInputType(options);
  }
  if (connectorType === 'pair') {
    if (inputType === 'conditional') return 'equal';
    if (inputType === 'association') return 'association';
    if (inputType === 'validation') return 'equal';
  }
  if (connectorType === 'output') {
    if (inputType === 'conditional') return 'then';
    if (inputType === 'assignment') return 'set';
  }
  return 'equal';
}

function connectorContent(connectorType, inputType, opts) {
  let connector = opts[`${connectorType}Connector`];
  
  if ((!connector && connectorType === 'output') || inputType === 'association') {
    connector = defaultConnector(connectorType, inputType);
  }
  
  let content = connector ? [connector] : connectors[connectorType];
  
  return content.map(function(item) {
    return {
      id: item, 
      name: I18n.t(`admin.wizard.connector.${item}`) 
    };
  });
}

// Selectors

const selectionTypes = [
  'text',
  'list',
  'wizardField',
  'userField',
  'userFieldOptions',
  'group',
  'category',
  'tag',
  'user'
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
    
  return EmberObject.create(params);
}

function newInput(options = {}, count) {
  const inputType = defaultInputType(options);
      
  let params = {
    type: inputType,
    pairs: A(
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
    
  if (count > 0) {
    params.connector = options.inputConnector;
  }
  
  if (['conditional', 'assignment'].indexOf(inputType) > -1 ||
      options.outputDefaultSelection ||
      options.outputConnector) {
    
    params['output_type'] = defaultSelectionType('output', options);
    params['output_connector'] = defaultConnector('output', inputType, options);
  }
    
  return EmberObject.create(params);
}

export {
  defaultInputType,
  defaultSelectionType,
  defaultConnector,
  connectorContent,
  inputTypesContent,
  selectionTypes,
  newInput,
  newPair
}