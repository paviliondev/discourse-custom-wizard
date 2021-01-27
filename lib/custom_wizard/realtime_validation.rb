class CustomWizard::RealtimeValidation
    cattr_accessor :types
      @@types ||= {
        suggested_topics: [:text]
      }
  end
  