# frozen_string_literal: true

describe ::TagsController, type: :request do
  fab!(:tag_1) { Fabricate(:tag, name: "Angus") }
  fab!(:tag_2) { Fabricate(:tag, name: "Faizaan") }
  fab!(:tag_3) { Fabricate(:tag, name: "Robert") }
  fab!(:tag_4) { Fabricate(:tag, name: "Eli") }
  fab!(:tag_5) { Fabricate(:tag, name: "Jeff") }

  fab!(:tag_group_1) { Fabricate(:tag_group, tags: [tag_1, tag_2]) }
  fab!(:tag_group_2) { Fabricate(:tag_group, tags: [tag_3, tag_4]) }

  before do
    ::RequestStore.store[:tag_groups] = nil
  end

  describe "#search" do
    context "tag group param present" do
      it "returns tags only in the tag group" do
        get "/tags/filter/search.json", params: { q: '', tag_groups: [tag_group_1.name, tag_group_2.name] }
        expect(response.status).to eq(200)
        results = response.parsed_body['results']
        names = results.map { |result| result['name'] }

        expected_tag_names = TagGroup
          .includes(:tags)
          .where(id: [tag_group_1.id, tag_group_2.id])
          .map { |tag_group| tag_group.tags.pluck(:name) }.flatten

        expect(names).to contain_exactly(*expected_tag_names)
      end
    end

    context "tag group param not present" do
      it "returns all tags" do
        get "/tags/filter/search.json", params: { q: '' }
        expect(response.status).to eq(200)
        results = response.parsed_body['results']
        names = results.map { |result| result['name'] }

        all_tag_names = Tag.all.pluck(:name)
        expect(names).to contain_exactly(*all_tag_names)
      end
    end
  end
end
