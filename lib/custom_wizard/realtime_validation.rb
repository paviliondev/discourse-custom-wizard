class CustomWizard::RealtimeValidation
    cattr_accessor :types
      @@types ||= {
        suggested_topics: {type: :text, component: "alpha-validator"}
      }
  end
  