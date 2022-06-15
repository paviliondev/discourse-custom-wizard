import I18n from "I18n";

const getThemeId = () => {
  let themeId = parseInt(
    document.querySelector("meta[name=discourse_theme_id]").content,
    10
  );

  if (!isNaN(themeId)) {
    return themeId.toString();
  } else {
    return null;
  }
};

const getThemeKey = (key) => {
  const themeId = getThemeId();
  return `theme_translations.${themeId}.${key}`;
};

const translationExists = (key) => {
  return (
    I18n.findTranslation(key, { locale: I18n.locale }) ||
    I18n.findTranslation(key, { locale: I18n.defaultLocale })
  );
};

const translatedText = (key, value) => {
  const themeKey = getThemeKey(key);
  return translationExists(themeKey) ? I18n.t(themeKey) : value;
};

export { translatedText };

const WizardI18n = (key, params = {}) => {
  const themeId = getThemeId();
  if (!themeId) {
    return I18n.t(key, params);
  }

  let themeKey = getThemeKey(key);

  if (translationExists(themeKey)) {
    return I18n.t(themeKey, params);
  } else {
    return I18n.t(key, params);
  }
};

export default WizardI18n;
