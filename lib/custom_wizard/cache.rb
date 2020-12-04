# frozen_string_literal: true

class ::CustomWizard::Cache
  def initialize(key)
    @key = "#{CustomWizard::PLUGIN_NAME}_#{key}"
  end
  
  def read
    cache.read(@key)
  end
  
  def write(data)
    synchronize { cache.write(@key, data) }
  end
  
  def delete
    synchronize { cache.delete(@key) }
  end
  
  def synchronize
    DistributedMutex.synchronize(@key) { yield }
  end
  
  def cache
    @cache ||= Discourse.cache
  end
  
  def self.wrap(key, &block)
    c = new(key)
        
    if cached = c.read
      cached
    else
      result = block.call()
      c.write(result)
      result
    end
  end
end