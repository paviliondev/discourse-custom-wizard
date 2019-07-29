import {ajax} from 'discourse/lib/ajax';

export default Ember.Controller.extend({
  init() {

    this._super();
    this.set('selected', new Set());
    this.set('filePath', []);


  },


  actions: {

    checkChanged(event) {

      let selected = this.get('selected');


      if (event.target.checked) {


        selected.add(event.target.id)

      } else if (!event.target.checked) {
        selected.delete(event.target.id)
      }
      console.log(selected);
      this.set('selected', selected)


    },


    export() {
      let wizards = this.get('selected');
      let url = Discourse.BaseUrl;
      let route = '/admin/wizards/transfer/export';
      url += route + '?';

      wizards.forEach((wizard) => {
        let step = 'wizards[]=' + wizard;
        step += '&';
        url += step
      });

      location.href = url;

      console.log(url)

    },

    setFilePath(event) {
      console.log(event.target.files[0]);

      // 512 kb is the max file size
      let maxFileSize = 512 * 1024;

      if (maxFileSize < event.target.files[0].size) {
        this.set('fileError', 'The file size is too big')
      } else {

        this.set('filePath', event.target.files[0])

      }

    }

    ,
    import() {

      let $formData = new FormData();
      $formData.append('file', this.get('filePath'));
      console.log($formData);

      ajax('/admin/wizards/transfer/import', {
        type: 'POST',
        data: $formData,
        processData: false,
        contentType: false,

      }).then(result => {
        if (result.error) {
          alert(result.error)

        } else {
          alert(result.success)
        }
      })

    }


  }


});
