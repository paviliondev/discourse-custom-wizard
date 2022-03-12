# frozen_string_literal: true
plugin = "discourse-custom-wizard"

SimpleCov.configure do
  track_files "plugins/#{plugin}/**/*.rb"
  add_filter { |src| !(src.filename =~ /(\/#{plugin}\/app\/|\/#{plugin}\/lib\/)/) }
end
