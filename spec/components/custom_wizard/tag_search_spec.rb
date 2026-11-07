# frozen_string_literal: true

describe CustomWizard::TagSearch do
  describe ".tag_names" do
    it "ignores unset values" do
      expect(described_class.tag_names([false, nil, "", "tag1", { "name" => "tag2" }])).to eq(
        %w[tag1 tag2],
      )
    end
  end
end
