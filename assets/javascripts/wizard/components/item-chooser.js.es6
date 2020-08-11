import MiniTagChooser from "select-kit/components/mini-tag-chooser";
import { ajax } from "discourse/lib/ajax";
import { observes } from "discourse-common/utils/decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default MiniTagChooser.extend({
  searchTags(url, data, callback){
    return ajax(url, {
      data: {
        name: data.name,
        value: data.q,
      }
    }).then(result => callback(this, result))
      .catch(popupAjaxError);
  },

  search(filter){
    const data = {
      q: filter,
      name: this.get('item')
    }

    return this.searchTags('/w/items/search', data, this._transformJson );

  },


  _transformJson(obj, result){
    let x = result.map(item => {
      return { id: item, name: item }
    })

    return x ;
  },

});
