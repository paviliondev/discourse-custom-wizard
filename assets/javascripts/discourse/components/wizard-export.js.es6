import Component from "@ember/component";
import { A } from "@ember/array";
import I18n from "I18n";

export default Component.extend({
  classNames: ['container', 'export'],
  selected: A(),

  actions: {
    checkChanged(event) {
      this.set('exportMessage', '');

      let selected = this.get('selected');

      if (event.target.checked) {
        selected.addObject(event.target.id);
      } else if (!event.target.checked) {
        selected.removeObject(event.target.id);
      }

      this.set('selected', selected);
    },

    export() {
      const wizards = this.get('selected');

      if (!wizards.length) {
        this.set('exportMessage', I18n.t("admin.wizard.transfer.export.none_selected"));
      } else {
        this.set('exportMessage', '');

        let url = Discourse.BaseUrl;
        let route = '/admin/wizards/transfer/export';
        url += route + '?';

        wizards.forEach((wizard) => {
          let step = 'wizards[]=' + wizard;
          step += '&';
          url += step;
        });

        location.href = url;
      }
    }
  }
});