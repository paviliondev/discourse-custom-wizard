# frozen_string_literal: true

module ::CustomWizard
  PLUGIN_NAME ||= 'custom_wizard'
  
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace CustomWizard
  end
end