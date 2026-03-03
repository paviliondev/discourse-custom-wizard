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
    let(:all_tag_names) { Tag.all.pluck(:name) }
    let(:filtered_tag_names) do
      ->(filter_params) do
        DiscourseTagging.filter_allowed_tags(guardian, filter_params).map(&:name)
      end
    end
    let(:expect_filtered_tag_names) do
      lambda do |filter_params, expected_tag_names|
        expect(filtered_tag_names.call(filter_params)).to contain_exactly(*expected_tag_names)
      end
    end
    let(:custom_wizard_for_input) do
      ->(groups) { { name: "custom-wizard-tag-chooser", groups: groups } }
    end

    context "for_input is a boolean" do
      it "works normally" do
        expect_filtered_tag_names.call({ q: "", for_input: true }, all_tag_names)
      end
    end

    context "for_input is an object including a tag group" do
      it "returns tags only in the tag group" do
        filter_params = { q: "", for_input: custom_wizard_for_input.call(tag_group_1.name) }
        expect_filtered_tag_names.call(filter_params, tag_group_1.tags.pluck(:name))
      end
    end

    context "for_input is an object including an empty tag group string" do
      it "returns all tags" do
        expect_filtered_tag_names.call(
          { q: "", for_input: custom_wizard_for_input.call("") },
          all_tag_names,
        )
      end
    end

    context "when selected_tags are parameter objects" do
      it "normalizes selected_tags and does not raise" do
        filter_params = {
          q: "",
          for_input: custom_wizard_for_input.call(tag_group_1.name),
          selected_tags:
            ActionController::Parameters.new(
              "0" => ActionController::Parameters.new(id: tag_1.id.to_s, name: tag_1.name),
              "1" => ActionController::Parameters.new(id: tag_2.id.to_s, name: tag_2.name),
            ),
        }

        tags = nil
        expect {
          tags = DiscourseTagging.filter_allowed_tags(guardian, filter_params)
        }.not_to raise_error
        expect(tags.map(&:name)).to be_empty
      end
    end
  end
end
