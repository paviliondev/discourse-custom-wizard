# frozen_string_literal: true
require_relative '../../../plugin_helper'

describe CustomWizard::AdminNoticeController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }

  before do
    sign_in(admin_user)
    @notice = CustomWizard::Notice.new(
      message: "Message about subscription",
      type: "info",
      created_at: Time.now - 3.day,
      expired_at: nil
    )
    @notice.save
  end

  it "lists notices" do
    get "/admin/wizards/notice.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body.length).to eq(1)
  end

  it "dismisses notices" do
    put "/admin/wizards/notice/#{@notice.id}.json"
    expect(response.status).to eq(200)

    updated = CustomWizard::Notice.find(@notice.id)
    expect(updated.dismissed?).to eq(true)
  end
end
