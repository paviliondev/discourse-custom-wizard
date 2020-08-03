class UpdateWatchCategoriesAction < ActiveRecord::Migration[6.0]
  def change
    watch_category_wizards = PluginStoreRow.where("
      plugin_name = 'custom_wizard' AND
      value::jsonb -> 'actions' @> '[{ \"type\" : \"watch_categories\" }]'::jsonb
    ")
    
    if watch_category_wizards.exists?
      watch_category_wizards.each do |row|
        begin
          wizard_json = JSON.parse(row.value)
        rescue TypeError, JSON::ParserError
          next
        end        
        
        wizard_json['actions'].each do |a|
          if a['type'] === "watch_categories" && a['wizard_user'] == nil
            a['wizard_user'] = true
          end
        end
        
        row.value = wizard_json.to_json
        row.save
      end
    end
  end
end