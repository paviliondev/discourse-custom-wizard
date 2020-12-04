# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-custom-wizard"
    track_files "plugins/discourse-custom-wizard/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb|api)/ }
  end
end

require 'rails_helper'