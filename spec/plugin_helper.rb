# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  root "plugins/discourse-custom-wizard"
  track_files "plugins/discourse-custom-wizard/**/*.rb"
  add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb|api)/ }
end

require 'rails_helper'