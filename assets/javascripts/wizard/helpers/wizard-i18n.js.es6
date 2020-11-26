import { registerUnbound } from 'discourse-common/lib/helpers';
import WizardI18n from '../lib/wizard-i18n';

export default registerUnbound("wizard-i18n", (key, params) => {
  return WizardI18n(key, params);
});