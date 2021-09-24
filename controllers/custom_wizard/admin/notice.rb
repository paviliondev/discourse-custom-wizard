# frozen_string_literal: true

class CustomWizard::AdminNoticeController < CustomWizard::AdminController
  before_action :find_notice, only: [:dismiss]

  def index
    render_serialized(CustomWizard::Notice.list, CustomWizard::NoticeSerializer)
  end

  def dismiss
    if @notice.dismissable? && @notice.dismiss
      render json: success_json.merge(dismissed_at: @notice.dismissed_at)
    else
      render json: failed_json
    end
  end

  def find_notice
    @notice = CustomWizard::Notice.find(params[:notice_id])
    raise Discourse::InvalidParameters.new(:notice_id) unless @notice
  end
end