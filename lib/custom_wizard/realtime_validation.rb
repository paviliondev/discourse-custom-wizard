class CustomWizard::RealtimeValidation
    cattr_accessor :types
      @@types ||= {
        similar_topics: { types: [:text], component: "similar-topics-validator", backend: true, required_params: [] }
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

    def self.similar_topics(params, current_user)
      title = params[:title]
      raw = params[:raw]
      categories = params[:categories]
      date_after = params[:date_after]

      if title.length < SiteSetting.min_title_similar_length || !Topic.count_exceeds_minimum?
        return []
      end
  
      topics = Topic.similar_to(title, raw, current_user).to_a
      topics.select! { |t| categories.include?(t.category.id.to_s) } if categories.present?
      topics.select! { |t| t.created_at > DateTime.parse(date_after) } if date_after.present?
      topics.map! { |t| SimilarTopic.new(t) }
      ::ActiveModel::ArraySerializer.new(topics, each_serializer: SimilarTopicSerializer, root: :similar_topics, rest_serializer: true, scope: ::Guardian.new(current_user))
    end
end
