# frozen_string_literal: true

require_relative '../../plugin_helper.rb'

describe CustomWizard::Cache do
  it "writes and reads values to the cache" do
    CustomWizard::Cache.new('list').write([1,2,3])
    expect(CustomWizard::Cache.new('list').read).to eq([1,2,3])
  end
  
  it "deletes values from the cache" do
    CustomWizard::Cache.new('list').delete
    expect(CustomWizard::Cache.new('list').read).to eq(nil)
  end
  
  describe "#wrap" do
    before do
      @raw = [1,2,3]
    end
    
    def list
      CustomWizard::Cache.wrap('list') { @raw }
    end
    
    it "returns value from passed block" do
      expect(list).to eq([1,2,3])
    end
    
    it "returns cached value" do
      cached = list
      @raw = [3,2,1]
      expect(list).to eq(cached)
    end
  end
end
