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
    answer: {
      types: %i[text dropdown],
      client: false,
      backend: false,
      required_params: [],
    },
  }
end
