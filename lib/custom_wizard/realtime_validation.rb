class CustomWizard::RealtimeValidation
    cattr_accessor :types
      @@types ||= {
        suggested_topics: { types: [:text], component: "suggested-validator", backend: true, required_params: [] }
      }

      class SimilarTopic
        def initialize(topic)
          @topic = topic
        end

        attr_reader :topic

        def blurb
          Search::GroupedSearchResults.blurb_for(cooked: @topic.try(:blurb))
        end
      end

    def self.suggested_topics(params, current_user)
      title = params[:title]
      raw = params[:raw]

      if title.length < SiteSetting.min_title_similar_length || !Topic.count_exceeds_minimum?
        return []
      end
  
      topics = Topic.similar_to(title, raw, current_user).to_a
      topics.map! { |t| SimilarTopic.new(t) }
      ::ActiveModel::ArraySerializer.new(topics, each_serializer: SimilarTopicSerializer, root: :similar_topics, rest_serializer: true, scope: ::Guardian.new(current_user))
    end
end
