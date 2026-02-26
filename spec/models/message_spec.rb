require 'rails_helper'

RSpec.describe Message, type: :model do
  subject { build(:message) }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  describe "associations" do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
  end

  describe "client message detection (via badge broadcast)" do
    let(:conversation) { create(:conversation) }

    it "broadcasts admin badge when message is from the conversation owner" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with("conversations_badge", any_args)
      create(:message, conversation: conversation, user: conversation.user)
    end

    it "broadcasts client badge when message is from a non-owner (admin)" do
      admin = create(:user, :admin)
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with("chat_bubble_user_#{conversation.user_id}", any_args)
      create(:message, conversation: conversation, user: admin)
    end
  end
end
