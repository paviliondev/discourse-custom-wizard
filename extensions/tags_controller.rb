# frozen_string_literal: true

module CustomWizardTagsController
  def search
    RequestStore.store[:tagGroups] = params[:tagGroups] if params[:tagGroups].present?
    super
  end
end
