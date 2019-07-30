import {ajax} from 'discourse/lib/ajax';

export default Ember.Controller.extend({
  init() {
    this._super();
    this.set('selected', Ember.A());
    this.set('filePath', Ember.A());
  },


  actions: {
    checkChanged(event) {
      let selected = this.get('selected');
      if (event.target.checked) {
        selected.addObject(event.target.id)
      } else if (!event.target.checked) {
        selected.removeObject(event.target.id)
      }
      console.log(selected);
      this.set('selected', selected)
    },

    export() {
      let wizards = this.get('selected');
      let url = Discourse.BaseUrl;
      let route = '/admin/wizards/transfer/export';
      url += route + '?';
      if (!wizards.length) {
        this.set('noneSelected', "Please select atleast one wizard")
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
      // 512 kb is the max file size
      let maxFileSize = 512 * 1024;
      if (event.target.files[0] === undefined) {
        this.get('filePath').length = 0
        return
      }
      if (maxFileSize < event.target.files[0].size) {
        this.set('fileError', 'The file size is too big')
      } else {
        // emptying the array as we allow only one file upload at a time
        this.get('filePath').length = 0
        // interestingly, this.get gives us the actual reference to the object so modifying it
        // actually modifies the actual value
        this.get('filePath').addObject(event.target.files[0])
        console.log(this.get('filePath'))
      }
    },

    import() {
      let $formData = new FormData();
      console.log(this.get('filePath'))
      if (this.get('filePath').length) {
        this.set('noFile', '')
        $formData.append('file', this.get('filePath')[0]);
        console.log($formData);
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
        this.set('noFile', 'Please choose a file to export')
      }
    }
  }
});
