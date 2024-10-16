# frozen_string_literal: true

describe ::DiscourseTagging, type: :request do
  fab!(:user)
  fab!(:tag_1) { Fabricate(:tag, name: "Angus") }
  fab!(:tag_2) { Fabricate(:tag, name: "Faizaan") }
  fab!(:tag_3) { Fabricate(:tag, name: "Robert") }
  fab!(:tag_4) { Fabricate(:tag, name: "Eli") }
  fab!(:tag_5) { Fabricate(:tag, name: "Jeff") }

  fab!(:tag_group_1) { Fabricate(:tag_group, tags: [tag_1, tag_2]) }
  fab!(:tag_group_2) { Fabricate(:tag_group, tags: [tag_3, tag_4]) }

  describe "#filter_allowed_tags" do
    let(:guardian) { Guardian.new(user) }

    context "for_input is a boolean" do
      it "works normally" do
        filter_params = { q: "", for_input: true }
        tags = DiscourseTagging.filter_allowed_tags(guardian, filter_params)
        names = tags.map(&:name)
        all_tag_names = Tag.all.pluck(:name)
        expect(names).to contain_exactly(*all_tag_names)
      end
    end

    context "for_input is an object including a tag group" do
      it "returns tags only in the tag group" do
        filter_params = {
          q: "",
          for_input: {
            name: "custom-wizard-tag-chooser",
            groups: tag_group_1.name,
          },
        }
        tags = DiscourseTagging.filter_allowed_tags(guardian, filter_params)
        names = tags.map(&:name)
        expected_tag_names =
          TagGroup
            .includes(:tags)
            .where(id: tag_group_1.id)
            .map { |tag_group| tag_group.tags.pluck(:name) }
            .flatten

        expect(names).to contain_exactly(*expected_tag_names)
      end
    end

    context "for_input is an object including an empty tag group string" do
      it "returns all tags" do
        filter_params = { q: "", for_input: { name: "custom-wizard-tag-chooser", groups: "" } }
        tags = DiscourseTagging.filter_allowed_tags(guardian, filter_params)
        names = tags.map(&:name)

        all_tag_names = Tag.all.pluck(:name)
        expect(names).to contain_exactly(*all_tag_names)
      end
    end
  end
end
