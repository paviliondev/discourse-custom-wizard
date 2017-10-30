class CustomWizard::Field
  def self.types
    @types ||= ['text', 'textarea', 'dropdown', 'image', 'radio']
  end

  def self.require_assets
    @require_assets ||= {}
  end

  def self.add_assets(type, plugin = nil, asset_paths = [])
    if type
      types.push(*type)
    end

    if plugin && asset_paths
      require_assets[plugin] = asset_paths
    end
  end
end
