require 'simplecov'

SimpleCov.configure do
  add_filter do |src|
    src.filename !~ /discourse-custom-wizard/ ||
    src.filename =~ /spec/
  end
end