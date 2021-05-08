# frozen_string_literal: true

require_relative '../plugin_helper'

describe "Sprockets: require_tree_discourse directive" do
  let(:discourse_asset_path) {
    "#{Rails.root}/app/assets/javascripts/"
  }
  let(:fixture_asset_path) {
    "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/sprockets/"
  }
  let(:test_file_contents) {
    "console.log('hello')"
  }
  let(:resolved_file_contents) {
    File.read(
     "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/sprockets/resolved_js_file_contents.txt"
    )
  }

  before do
    @env ||= Sprockets::Environment.new
    discourse_asset_path = "#{Rails.root}/app/assets/javascripts/"
    fixture_asset_path = "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/sprockets/"
    @env.append_path(discourse_asset_path)
    @env.append_path(fixture_asset_path)
    @env.cache = {}
  end

  def create_tmp_folder_and_run(path, file_contents, &block)
    dir = File.dirname(path)
    unless File.directory?(dir)
      FileUtils.mkdir_p(dir)
    end

    File.new(path, 'w')
    File.write(path, file_contents)
    yield block if block_given?
    FileUtils.rm_r(dir)
  end

  it "includes assets from the discourse core" do
    create_tmp_folder_and_run("#{discourse_asset_path}/sptest/test.js", test_file_contents) do
      expect(@env.find_asset("require_tree_discourse_test.js").to_s).to eq(resolved_file_contents)
    end
  end

  it "throws ArgumentError if path is empty" do
    expect { @env.find_asset("require_tree_discourse_empty.js") }.to raise_error(CustomWizard::SprocketsEmptyPath).with_message("path cannot be empty")
  end

  it "throws ArgumentError if path is non non-existent" do
    expect { @env.find_asset("require_tree_discourse_non_existant.js") }.to raise_error(CustomWizard::SprocketsFileNotFound)
  end
end
