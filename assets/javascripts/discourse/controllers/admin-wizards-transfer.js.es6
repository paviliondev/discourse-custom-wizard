import { ajax } from 'discourse/lib/ajax';

export default Ember.Controller.extend({
  init() {
    this._super();
    this.set('selected', Ember.A());
    this.set('filePath', Ember.A());
  },

  actions: {
    checkChanged(event) {
      this.set('noneSelected','')
      let selected = this.get('selected');
      if (event.target.checked) {
        selected.addObject(event.target.id)
      } else if (!event.target.checked) {
        selected.removeObject(event.target.id)
      }
      this.set('selected', selected)
    },

    export() {
      let wizards = this.get('selected');
      let url = Discourse.BaseUrl;
      let route = '/admin/wizards/transfer/export';
      url += route + '?';
      if (!wizards.length) {
        this.set('noneSelected', I18n.t("admin.wizard.transfer.export.noneSelected"))
      } else {
        this.set('noneSelected', '')
        wizards.forEach((wizard) => {
          let step = 'wizards[]=' + wizard;
          step += '&';
          url += step
        });
        location.href = url;
      }
    },

    setFilePath(event) {
      this.set('noFile', '')
      // 512 kb is the max file size
      let maxFileSize = 512 * 1024;
      if (event.target.files[0] === undefined) {
        this.get('filePath').length = 0
        return
      }
      if (maxFileSize < event.target.files[0].size) {
        this.set('fileSizeError', I18n.t('admin.wizard.transfer.import.fileSizeError'))
      } else {
        this.set('fileSizeError', '')
        // emptying the array as we allow only one file upload at a time
        this.get('filePath').length = 0
        // interestingly, this.get gives us the actual reference to the object so modifying it
        // actually modifies the actual value
        this.get('filePath').addObject(event.target.files[0])
      }
    },

    import() {
      let $formData = new FormData();
      if (this.get('filePath').length) {
        this.set('noFile', '')
        $formData.append('file', this.get('filePath')[0]);
        ajax('/admin/wizards/transfer/import', {
          type: 'POST',
          data: $formData,
          processData: false,
          contentType: false,
        }).then(result => {
          if (result.error) {
            this.set('error', result.error)
          } else {
            this.set('success_ids', result.success)
            this.set('failure_ids', result.failed)
          }
        })
      } else {
        this.set('noFile',I18n.t("admin.wizard.transfer.import.noFile"))
      }
    }
  }
});
