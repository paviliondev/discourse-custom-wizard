# frozen_string_literal: true

describe ::CustomWizard::RealtimeValidation::SimilarTopics do
  let(:post) {  create_post(title: "matching similar topic") }
  let(:topic) {  post.topic }

  let(:category) { Fabricate(:category) }
  let(:cat_post) {  create_post(title: "matching similar topic slightly different", category: category) }
  let(:cat_topic) {  cat_post.topic }
  let(:user) { cat_post.user }

  before do
    SiteSetting.min_title_similar_length = 5
    Topic.stubs(:count_exceeds_minimum?).returns(true)
    SearchIndexer.enable
  end

  it "fetches similar topics" do
    validation = ::CustomWizard::RealtimeValidation::SimilarTopics.new(user)
    result = validation.perform({ title: topic.title.chars.take(10).join })
    expect(result.items.length).to eq(2)
  end

  it "filters topics based on category" do
    validation = ::CustomWizard::RealtimeValidation::SimilarTopics.new(user)
    result = validation.perform({ title: "matching similar", categories: [category.id.to_s] })
    expect(result.items.length).to eq(1)
  end

  it "filters topics based on Max Topic Age setting" do
    topic.update!(created_at: 23.hours.ago)
    cat_topic.update!(created_at: 2.days.ago)

    validation = ::CustomWizard::RealtimeValidation::SimilarTopics.new(user)
    result = validation.perform({ title: "matching similar", time_n_value: 1, time_unit: "days" })
    expect(result.items.length).to eq(1)
  end
end
