module ::CustomWizard
  class Engine < ::Rails::Engine
    engine_name 'custom_wizard'
    isolate_namespace CustomWizard
  end
end