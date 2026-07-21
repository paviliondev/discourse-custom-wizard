# frozen_string_literal: true

describe CustomWizard::TagsController do
  fab!(:user)
  fab!(:tag_1) { Fabricate(:tag, name: "Angus") }
  fab!(:tag_2) { Fabricate(:tag, name: "Faizaan") }
  fab!(:tag_3) { Fabricate(:tag, name: "Robert") }
  fab!(:tag_4) { Fabricate(:tag, name: "Eli") }

  fab!(:tag_group_1) { Fabricate(:tag_group, tags: [tag_1, tag_2]) }
  fab!(:tag_group_2) { Fabricate(:tag_group, tags: [tag_3, tag_4]) }

  before { sign_in(user) }

  def search(params)
    get "/custom-wizard/tags/search.json", params: params
    expect(response.status).to eq(200)
    response.parsed_body["results"].map { |result| result["name"] }
  end

  it "restricts results to the tags in the given tag group" do
    expect(search(tag_groups: tag_group_1.name)).to contain_exactly("Angus", "Faizaan")
  end

  it "supports more than one tag group" do
    expect(search(tag_groups: "#{tag_group_1.name},#{tag_group_2.name}")).to contain_exactly(
      "Angus",
      "Faizaan",
      "Robert",
      "Eli",
    )
  end

  it "filters within the tag group by the query term" do
    expect(search(tag_groups: tag_group_1.name, q: "ang")).to contain_exactly("Angus")
  end

  it "excludes already-selected tags from results" do
    expect(search(tag_groups: tag_group_1.name, selected_tags: [tag_1.name])).to contain_exactly(
      "Faizaan",
    )
  end

  it "restricts results to the field content allow-list" do
    expect(search(content: [tag_1.name, tag_3.name])).to contain_exactly("Angus", "Robert")
  end

  it "allows tags from either the tag group or the content allow-list" do
    expect(search(tag_groups: tag_group_1.name, content: [tag_3.name])).to contain_exactly(
      "Angus",
      "Faizaan",
      "Robert",
    )
  end

  it "returns all tags when neither a tag group nor content is given" do
    expect(search({})).to contain_exactly("Angus", "Faizaan", "Robert", "Eli")
  end

  it "returns no tags when the tag group does not exist" do
    expect(search(tag_groups: "does-not-exist")).to be_empty
  end

  context "with a hidden (staff-only) tag in the allow-list" do
    fab!(:hidden_tag) { Fabricate(:tag, name: "Secret") }
    fab!(:hidden_group) do
      Fabricate(:tag_group, permissions: { "staff" => 1 }, tag_names: [hidden_tag.name])
    end

    it "does not expose it to non-staff users" do
      expect(search(content: [tag_1.name, hidden_tag.name])).to contain_exactly("Angus")
    end

    it "exposes it to staff" do
      sign_in(Fabricate(:admin))
      expect(search(content: [tag_1.name, hidden_tag.name])).to contain_exactly("Angus", "Secret")
    end
  end
end
