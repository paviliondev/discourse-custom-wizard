# frozen_string_literal: true

class CustomWizard::RealtimeValidation
  cattr_accessor :types

  @@types ||= {
    similar_topics: {
      types: [:text],
      component: "similar-topics-validator",
      backend: true,
      required_params: [],
    },
  }
end
