# frozen_string_literal: true

require_relative '../../../plugin_helper'

describe CustomWizard::ProAuthenticationSerializer do
  fab!(:user) { Fabricate(:user) }

  it 'should return pro authentication attributes' do
    auth = CustomWizard::ProAuthentication.new(OpenStruct.new(key: '1234', auth_at: Time.now, auth_by: user.id))
    serialized = described_class.new(auth, root: false).as_json

    expect(serialized[:active]).to eq(true)
    expect(serialized[:client_id]).to eq(auth.client_id)
    expect(serialized[:auth_by]).to eq(auth.auth_by)
    expect(serialized[:auth_at]).to eq(auth.auth_at)
  end
end
