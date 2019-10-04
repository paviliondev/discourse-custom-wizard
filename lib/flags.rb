class CustomWizard::Flag
    def initialize(id, name, value)
        @id     = id
        @name   = name
        @value = value
    end

    def id
        @id
    end

    def name
        @name
    end

    def value
        @value
    end
end

class CustomWizard::Flags

    def self.list
        raw_flags = YAML.safe_load(File.read(File.join(Rails.root, 'plugins', 'discourse-custom-wizard', 'config', 'national_flags.yml')))

        flagscollection = []

        raw_flags.map do |name, code| 
            flagscollection << CustomWizard::Flag.new(name, name, code)
        end

        flagscollection
    end
end
