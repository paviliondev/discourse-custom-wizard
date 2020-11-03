require 'simplecov'

SimpleCov.configure do
  add_filter do |src|
    src.filename !~ /discourse-custom-wizard/ ||
    src.filename =~ /spec/ ||
    src.filename =~ /db/ ||
    src.filename =~ /api/ ## API features are currently experimental
  end
end