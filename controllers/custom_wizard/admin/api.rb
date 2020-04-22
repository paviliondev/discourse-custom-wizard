class CustomWizard::AdminApiController < CustomWizard::AdminController
  skip_before_action :check_xhr, only: [:redirect]

  def list
    serializer = ActiveModel::ArraySerializer.new(CustomWizard::Api.list,
      each_serializer: CustomWizard::BasicApiSerializer
    )
    render json: MultiJson.dump(serializer)
  end

  def find
    render_serialized(CustomWizard::Api.get(api_params[:name]), CustomWizard::ApiSerializer, root: false)
  end

  def save
    current = CustomWizard::Api.get(api_params[:name])

    if api_params[:new] && current
      raise Discourse::InvalidParameters, "An API with that name already exists: '#{current.title || current.name}'"
    end

    PluginStoreRow.transaction do
      CustomWizard::Api.set(api_params[:name], title: api_params[:title])

      if auth_data.present?
        auth_data['auth_params'] = auth_data['auth_params'] || []
        CustomWizard::Api::Authorization.set(api_params[:name], auth_data)
      end

      if api_params[:endpoints].is_a? String
        begin
          endpoints = JSON.parse(api_params[:endpoints])
          endpoints.each do |endpoint|
            CustomWizard::Api::Endpoint.set(api_params[:name], endpoint)
          end
        rescue => e
          puts e
        end
      end
    end

    render json: success_json.merge(
      api: CustomWizard::ApiSerializer.new(
        CustomWizard::Api.get(api_params[:name]),
        root: false
      )
    )
  end

  def remove
    PluginStoreRow.transaction do
      CustomWizard::Api.remove(api_params[:name])
      CustomWizard::Api::Authorization.remove(api_params[:name])
      CustomWizard::Api::Endpoint.remove(api_params[:name])
      CustomWizard::Api::LogEntry.clear(api_params[:name])
    end

    render json: success_json
  end

  def authorize
    result = CustomWizard::Api::Authorization.get_token(api_params[:name])

    if result.instance_variable_defined?(:@error)
      render json: failed_json.merge(message: result['error_description'] || result['error'])
    else
      render json: success_json.merge(
        api: CustomWizard::ApiSerializer.new(
          CustomWizard::Api.get(api_params[:name]),
          root: false
        )
      )
    end
  end

  def clearlogs
    CustomWizard::Api::LogEntry.clear(api_params[:name])
    render json: success_json
  end

  def redirect
    params.require(:name)
    params.require(:code)

    CustomWizard::Api::Authorization.set(params[:name], code: params[:code])
    CustomWizard::Api::Authorization.get_token(params[:name])

    return redirect_to path('/admin/wizards/apis/' + params[:name])
  end

  private

  def api_params
    params.require(:name)

    data = params.permit(
      :name,
      :title,
      :auth_type,
      :auth_url,
      :token_url,
      :client_id,
      :client_secret,
      :username,
      :password,
      :auth_params,
      :endpoints,
      :new
    ).to_h

    data[:name] = data[:name].underscore

    @api_params ||= data
  end

  def auth_data
    auth_data = api_params.slice(
      :auth_type,
      :auth_url,
      :token_url,
      :client_id,
      :client_secret,
      :username,
      :password,
      :auth_params
    )

    auth_data[:auth_params] = JSON.parse(auth_data[:auth_params]) if auth_data[:auth_params].present?

    @auth_data ||= auth_data
  end
end
