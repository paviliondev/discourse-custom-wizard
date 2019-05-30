class CustomWizard::AdminApiController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin
  skip_before_action :check_xhr, only: [:redirect]

  def index
  end

  def list
    serializer = ActiveModel::ArraySerializer.new(
      CustomWizard::Authorization.list,
      each_serializer: CustomWizard::ApiListItemSerializer
    )

    render json: MultiJson.dump(serializer)
  end

  def find
    params.require(:service)
    render_serialized(CustomWizard::Authorization.get(params[:service]), CustomWizard::ApiSerializer, root: false)
  end

  def save
    params.require(:service)

    data = params.permit(
      :service,
      :auth_type,
      :auth_url,
      :token_url,
      :client_id,
      :client_secret,
      :username,
      :password,
      :auth_params
    ).to_h

    data[:auth_params] = JSON.parse(data[:auth_params]) if data[:auth_params]

    result = CustomWizard::Authorization.set(data[:service], data.except!(:service))

    render json: success_json.merge(api: CustomWizard::ApiSerializer.new(result, root: false))
  end

  def redirect
   params.require(:service)
   params.require(:code)

   CustomWizard::Authorization.set(params[:service], code: params[:code])

   CustomWizard::Authorization.get_token(params[:service])

   return redirect_to path('/admin/wizards/apis/' + params[:service])
  end
end
