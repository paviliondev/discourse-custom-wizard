import {ajax} from 'discourse/lib/ajax';

export default Ember.Controller.extend({
  init() {

    this._super();
    this.set('selected', new Set());
    this.set('filePath', []);
    // this.setProperties({selected:[]})

  },


  actions: {

    checkChanged(event) {
      // return true;
      // console.log(event.target.checked)

      let selected = this.get('selected')


      if (event.target.checked) {


        selected.add(event.target.id)

      } else if (!event.target.checked) {
        selected.delete(event.target.id)
      }
      console.log(selected)
      this.set('selected', selected)

      // console.log(this.get('selected'))


    },


    export() {
      let wizards = this.get('selected')
      let url = Discourse.BaseUrl
      let route = '/admin/wizards/transfer/export'
      url += route + '?'

      wizards.forEach((wizard) => {
        let step = 'wizards[]=' + wizard;
        step += '&'
        url += step
      })

      location.href = url;

      console.log(url)
      // return ajax('/admin/wizards/transfer/export', {
      //   type: "POST",
      //   data: {
      //     wizards: wizards
      //   }
      //
      // })


    },

    setFilePath(event) {
      console.log(event.target.files[0])

      this.set('filePath', event.target.files[0])

    }

    ,
    import() {
      let fileReader = new FileReader();
      fileReader.onload = function () {
        let upload = {'fileJson': fileReader.result};
        // ajax('admin/wizard/transfer/import');
        console.log(fileReader.result)
        //ajax call

        ajax('/admin/wizards/transfer/import',{
          type: 'POST' ,
          data:upload ,

        }).then(result=>{
          if(result.error){
            console.log(result.error)

          }else{
            alert('wizards imported successfully')
          }
        })
      }
      fileReader.readAsText(this.get('filePath'))

    }


  }


});
