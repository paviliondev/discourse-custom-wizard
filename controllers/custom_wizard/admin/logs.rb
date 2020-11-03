class CustomWizard::AdminLogsController < CustomWizard::AdminController
  def index
    render_serialized(
      CustomWizard::Log.list(params[:page].to_i, params[:limit].to_i),
      CustomWizard::LogSerializer
    )
  end
end