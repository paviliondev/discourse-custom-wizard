class CustomWizard::Flag
    def initialize(id, name)
        @id = id
        @name = name
    end

    def id
        @id
    end

    def name
        @name
    end
end

class CustomWizard::Flags

    def self.list
        raw_flags = YAML.safe_load(File.read(File.join(Rails.root, 'plugins', 'discourse-custom-wizard', 'config', 'national_flags.yml')))

        flagscollection = []

        raw_flags.map do |name, pic| 
            # This is super hacky.  Adding the trailing space actually stops search breaking in the dropdown! (and doesn't compromise the view!)
            # Feeding just name, name will break search
            flagscollection << CustomWizard::Flag.new(name, "#{name} ")
        end

        flagscollection
    end
end
