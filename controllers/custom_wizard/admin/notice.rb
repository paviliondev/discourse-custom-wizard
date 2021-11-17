# frozen_string_literal: true

class CustomWizard::AdminNoticeController < CustomWizard::AdminController
  before_action :find_notice, only: [:dismiss, :hide]

  def index
    type = params[:type]
    archetype = params[:archtype]
    page = params[:page].to_i
    include_all = ActiveRecord::Type::Boolean.new.cast(params[:include_all])
    visible = ActiveRecord::Type::Boolean.new.cast(params[:visible])

    if type
      if type.is_a?(Array)
        type = type.map { |t| CustomWizard::Notice.types[t.to_sym] }
      else
        type = CustomWizard::Notice.types[type.to_sym]
      end
    end

    if archetype
      if archetype.is_a?(Array)
        archetype = archetype.map { |t| CustomWizard::Notice.archetypes[archetype.to_sym] }
      else
        archetype = CustomWizard::Notice.archetypes[archetype.to_sym]
      end
    end

    notices = CustomWizard::Notice.list(
      include_all: include_all,
      page: page,
      type: type,
      archetype: archetype,
      visible: visible
    )

    render_serialized(notices, CustomWizard::NoticeSerializer, root: :notices)
  end

  def dismiss
    if @notice.dismissable? && @notice.dismiss!
      render json: success_json.merge(dismissed_at: @notice.dismissed_at)
    else
      render json: failed_json
    end
  end

  def hide
    if @notice.can_hide? && @notice.hide!
      render json: success_json.merge(hidden_at: @notice.hidden_at)
    else
      render json: failed_json
    end
  end

  def dismiss_all
    if CustomWizard::Notice.dismiss_all
      render json: success_json
    else
      render json: failed_json
    end
  end

  def find_notice
    @notice = CustomWizard::Notice.find(params[:notice_id])
    raise Discourse::InvalidParameters.new(:notice_id) unless @notice
  end
end
