# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-custom-wizard"
    track_files "plugins/discourse-custom-wizard/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb|api|gems)/ }
    SimpleCov.minimum_coverage 80
  end
end

require 'oj'
Oj.default_options = Oj.default_options.merge(cache_str: -1)

require 'rails_helper'
