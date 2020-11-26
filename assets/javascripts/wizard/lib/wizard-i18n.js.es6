import I18n from "I18n";

const getThemeId = () => {
  let themeId = parseInt($("meta[name=discourse_theme_ids]")[0].content, 10);
  
  if (!isNaN(themeId)) {
    return themeId.toString();
  } else {
    return null;
  }
}

const translationExists = (key) => {
  return I18n.findTranslation(key, { locale: I18n.locale }) ||
    I18n.findTranslation(key, { locale: I18n.defaultLocale });
} 

const WizardI18n = (key, params={}) => {
  const themeId = getThemeId();
  if (!themeId) return I18n.t(key, params);
  
  const themeKey = `theme_translations.${themeId}.${key}`;
    
  if (translationExists(themeKey)) {
    return I18n.t(themeKey, params);
  } else {
    return I18n.t(key, params);
  }
}

export default WizardI18n; 