export default Ember.Component.extend({
  classNames: ['container', 'export'],
  selected: Ember.A(),

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