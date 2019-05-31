class CustomWizard::ApiController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin
  skip_before_action :check_xhr, only: [:redirect]

  def index
  end

  def list
    serializer = ActiveModel::ArraySerializer.new(
      CustomWizard::Api.list,
      each_serializer: CustomWizard::BasicApiSerializer
    )

    render json: MultiJson.dump(serializer)
  end

  def find
    params.require(:service)
    render_serialized(CustomWizard::Api.new(params[:service]), CustomWizard::ApiSerializer, root: false)
  end

  def save
    byebug
    params.require(:service)
    service = params.permit(:service)
    auth_data = params[:auth_params]
    endpoints_data = params[:endpoints]

    service_auth_data = JSON.parse(auth_data) if !auth_data.nil?
    service_endpoints = JSON.parse(endpoints_data) if !endpoints_data.nil?

    if !service_auth_data.nil?
      CustomWizard::Api::Authorization.set(service, service_auth_data)
    end

    if !service_endpoints.nil?
      service_endpoints.each do |endpoint|
        CustomWizard::Api::Endpoint.set(service, endpoint)
      end
    end

    render json: success_json.merge(
      api: CustomWizard::ApiSerializer.new(params[:service], root: false)
    )
  end

  def redirect
   params.require(:service)
   params.require(:code)

   CustomWizard::Api::Authorization.set(params[:service], code: params[:code])

   CustomWizard::Api::Authorization.get_token(params[:service])

   return redirect_to path('/admin/wizards/apis/' + params[:service])
  end

  private

  def auth_data
    @auth_data ||= params.permit(
      :auth_type,
      :auth_url,
      :token_url,
      :client_id,
      :client_secret,
      :username,
      :password,
      :auth_params
    ).to_h
  end

  def endpoint_data
    @endpoint_data ||= JSON.parse(params.permit(endpoints: [:id, :type, :url]))
  end
end
