import { ajax } from 'discourse/lib/ajax';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: ['container', 'import'],
  hasLogs: Ember.computed.notEmpty('logs'),

  @computed('successIds', 'failureIds')
  logs(successIds, failureIds) {
    let logs = [];

    if (successIds) {
      logs.push(...successIds.map(id => {
        return { id, type: 'success' };
      }));
    }

    if (failureIds) {
      logs.push(...failureIds.map(id => {
        return { id, type: 'failure' };
      }));
    }

    return logs;
  },

  actions: {
    setFilePath(event) {
      this.set('importMessage', '');

      // 512 kb is the max file size
      let maxFileSize = 512 * 1024;

      if (event.target.files[0] === undefined) {
        this.set('filePath', null);
        return;
      }

      if (maxFileSize < event.target.files[0].size) {
        this.setProperties({
          importMessage: I18n.t('admin.wizard.transfer.import.file_size_error'),
          filePath: null
        });
        $('#file-url').val('');
      } else {
        this.set('filePath', event.target.files[0]);
      }
    },

    import() {
      const filePath = this.get('filePath');
      let $formData = new FormData();

      if (filePath) {
        $formData.append('file', filePath);

        ajax('/admin/wizards/transfer/import', {
          type: 'POST',
          data: $formData,
          processData: false,
          contentType: false,
        }).then(result => {
          if (result.error) {
            this.set('importMessage', result.error);
          } else {
            this.setProperties({
              successIds: result.success,
              failureIds: result.failed,
              fileName: $('#file-url')[0].files[0].name
            });
          }

          this.set('filePath', null);
          $('#file-url').val('');
        });
      } else {
        this.set('importMessage', I18n.t("admin.wizard.transfer.import.no_file"));
      }
    }
  }
});