# frozen_string_literal: true
class CustomWizard::AdminLogsController < CustomWizard::AdminController
  before_action :find_wizard, except: [:index]

  def index
    render json: ActiveModel::ArraySerializer.new(
      CustomWizard::Wizard.list(current_user),
      each_serializer: CustomWizard::BasicWizardSerializer
    )
  end

  def show
    render_json_dump(
      wizard: CustomWizard::BasicWizardSerializer.new(@wizard, root: false),
      logs: ActiveModel::ArraySerializer.new(
        log_list.logs,
        each_serializer: CustomWizard::LogSerializer
      ),
      total: log_list.total
    )
  end

  protected

  def log_list
    @log_list ||= begin
      list = CustomWizard::Log.list(params[:page].to_i, params[:limit].to_i, params[:wizard_id])

      if list.logs.any? && (usernames = list.logs.map(&:username)).present?
        user_map = User.where(username: usernames)
          .reduce({}) do |result, user|
            result[user.username] = user
            result
          end

        list.logs.each do |log_item|
          log_item.user = user_map[log_item.username]
        end
      end

      list
    end
  end
end
