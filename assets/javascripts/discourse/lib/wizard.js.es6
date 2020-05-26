import EmberObject from "@ember/object";
import wizardSchema from './wizard-schema';

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

const userProperties = [
  'name',
  'username',
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

const notificationLevels = [
  'regular',
  'watching',
  'tracking',
  'watching_first_post',
  'muted'
];

function listProperties(type, opts={}) {
  let properties = Object.keys(wizardSchema[type].basic);
  
  const types = wizardSchema[type].types;
  
  if (types) {
    let typeProperties = [];
    
    if (opts.allTypes) {
      Object.keys(types).forEach(type => {
        typeProperties = typeProperties.concat(Object.keys(types[type]));
      });
    } else if (opts.objectType && types[opts.objectType]) {
      typeProperties = Object.keys(types[opts.objectType]);
    }
    
    properties = properties.concat(typeProperties);
  }
    
  return properties;
}

function wizardFieldList(steps = [], opts = {}) {
  let upToIndex = null;
  
  if (opts.upTo) {
    upToIndex = steps.map((s) => (s.id)).indexOf(opts.upTo);
  }
     
  return steps.reduce((result, step, index) => {
    let fields = step.fields;
  
    if (fields && fields.length > 0) {
            
      if (upToIndex === null || index < upToIndex) {
        result.push(...fields.map((field) => {
          return EmberObject.create({
            id: field.id,
            label: `${field.label} (${field.id})`,
            type: field.type
          });
        }));
      }
    }
    
    return result;
  }, []);
}

export {
  selectKitContent,
  generateName,
  generateId,
  camelCase,
  snakeCase,
  userProperties,
  listProperties,
  notificationLevels,
  wizardFieldList
};