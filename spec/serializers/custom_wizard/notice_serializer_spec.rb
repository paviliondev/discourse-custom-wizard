# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::NoticeSerializer do
  before do
    @notice = CustomWizard::Notice.new(
      message: "Message about subscription",
      type: "info",
      created_at: Time.now - 3.day,
      expired_at: nil
    )
    @notice.save
  end

  it 'should return notice attributes' do
    serialized_notice = described_class.new(@notice)
    expect(serialized_notice.message).to eq(@notice.message)
    expect(serialized_notice.type).to eq(CustomWizard::Notice.types.key(@notice.type))
    expect(serialized_notice.dismissable).to eq(true)
  end
end
