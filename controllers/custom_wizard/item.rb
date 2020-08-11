class CustomWizard::ItemsController < ::ApplicationController
  def search
    search_params = {
      name: params[:name],
      value: params[:value] || '',
      limit: params[:limit] || 5
    }
    items = CustomWizard::Item.search(search_params)

    render json: MultiJson.dump(items)
  end
end
