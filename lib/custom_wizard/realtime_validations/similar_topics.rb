class CustomWizard::RealtimeValidation::SimilarTopics
  attr_accessor :user

  def initialize(user)
    @user = user
  end

  class SimilarTopic
    def initialize(topic)
      @topic = topic
    end

    attr_reader :topic

    def blurb
      Search::GroupedSearchResults.blurb_for(cooked: @topic.try(:blurb))
    end
  end

  def perform(params)
    title = params[:title]
    raw = params[:raw]
    categories = params[:categories]
    date_after = params[:date_after]

    result = CustomWizard::RealtimeValidation::Result.new(:similar_topic)

    if title.length < SiteSetting.min_title_similar_length || !Topic.count_exceeds_minimum?
      return result
    end

    topics = Topic.similar_to(title, raw, user).to_a
    topics.select! { |t| categories.include?(t.category.id.to_s) } if categories.present?
    topics.select! { |t| t.created_at > DateTime.parse(date_after) } if date_after.present?
    topics.map! { |t| SimilarTopic.new(t) }

    result.items = topics
    result.serializer_opts = { root: :similar_topics }

    result
  end
end
