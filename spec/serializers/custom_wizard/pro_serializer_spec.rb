# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::ProSerializer do
  it 'should return pro attributes' do
    pro = CustomWizard::Pro.new
    serialized = described_class.new(pro, root: false)

    expect(serialized.server).to eq(pro.server)
    expect(serialized.authentication.class).to eq(CustomWizard::ProAuthentication)
    expect(serialized.subscription.class).to eq(CustomWizard::ProSubscription)
  end
end
