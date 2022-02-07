# frozen_string_literal: true

module CustomWizardTagsController
  def search
    RequestStore.store[:tag_groups] = params[:tag_groups] if params[:tag_groups].present?
    super
  end
end
