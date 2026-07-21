# frozen_string_literal: true

class CustomWizard::TagsController < ::ApplicationController
  requires_plugin "discourse-custom-wizard"

  def search
    render_json_dump(results: CustomWizard::TagSearch.new(guardian, params).results)
  end
end
