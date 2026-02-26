require 'rails_helper'

RSpec.describe Conversation, type: :model do
  subject { build(:conversation) }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
  end

  describe ".recent" do
    it "orders by updated_at descending" do
      older = create(:conversation)
      newer = create(:conversation)
      newer.update_column(:updated_at, 1.hour.from_now)
      expect(Conversation.recent.first).to eq(newer)
      expect(Conversation.recent.last).to eq(older)
    end
  end

  describe "#unread_for_admin" do
    let(:conversation) { create(:conversation) }
    let(:client_user)  { conversation.user }
    let(:admin_user)   { create(:user, :admin) }

    it "returns unread messages from the client only" do
      unread = create(:message, conversation: conversation, user: client_user, read_at: nil)
      create(:message, conversation: conversation, user: client_user, read_at: 1.hour.ago)
      create(:message, conversation: conversation, user: admin_user,  read_at: nil)
      expect(conversation.unread_for_admin).to contain_exactly(unread)
    end
  end

  describe "#unread_for_client" do
    let(:conversation) { create(:conversation) }
    let(:client_user)  { conversation.user }
    let(:admin_user)   { create(:user, :admin) }

    it "returns unread messages from non-client users only" do
      unread = create(:message, conversation: conversation, user: admin_user,  read_at: nil)
      create(:message, conversation: conversation, user: admin_user,  read_at: 1.hour.ago)
      create(:message, conversation: conversation, user: client_user, read_at: nil)
      expect(conversation.unread_for_client).to contain_exactly(unread)
    end
  end

  describe ".admin_unread_count" do
    it "counts distinct conversations with at least one unread client message" do
      conv_unread = create(:conversation)
      conv_read   = create(:conversation)
      create(:conversation) # no messages

      create(:message, conversation: conv_unread, user: conv_unread.user, read_at: nil)
      create(:message, conversation: conv_unread, user: conv_unread.user, read_at: nil) # two unread, still 1 conv
      create(:message, conversation: conv_read,   user: conv_read.user,   read_at: 1.hour.ago)

      expect(Conversation.admin_unread_count).to eq(1)
    end

    it "does not count admin messages as unread for admin" do
      conversation = create(:conversation)
      admin = create(:user, :admin)
      create(:message, conversation: conversation, user: admin, read_at: nil)

      expect(Conversation.admin_unread_count).to eq(0)
    end
  end

  describe "#client_messages_seen_by_admin?" do
    let(:conversation) { create(:conversation) }

    context "when the last client message has been read" do
      it "returns true" do
        create(:message, conversation: conversation, user: conversation.user, read_at: 1.hour.ago)
        expect(conversation.client_messages_seen_by_admin?).to be true
      end
    end

    context "when the last client message has not been read" do
      it "returns false" do
        create(:message, conversation: conversation, user: conversation.user, read_at: nil)
        expect(conversation.client_messages_seen_by_admin?).to be false
      end
    end

    context "when there are no client messages" do
      it "returns false" do
        expect(conversation.client_messages_seen_by_admin?).to be false
      end
    end

    context "when a new unread message follows a read one" do
      it "returns false because the last message is unread" do
        create(:message, conversation: conversation, user: conversation.user, read_at: 1.hour.ago)
        create(:message, conversation: conversation, user: conversation.user, read_at: nil)
        expect(conversation.client_messages_seen_by_admin?).to be false
      end
    end
  end

  describe "#admin_messages_seen_by_client?" do
    let(:conversation) { create(:conversation) }
    let(:admin_user)   { create(:user, :admin) }

    context "when the last admin message has been read" do
      it "returns true" do
        create(:message, conversation: conversation, user: admin_user, read_at: 1.hour.ago)
        expect(conversation.admin_messages_seen_by_client?).to be true
      end
    end

    context "when the last admin message has not been read" do
      it "returns false" do
        create(:message, conversation: conversation, user: admin_user, read_at: nil)
        expect(conversation.admin_messages_seen_by_client?).to be false
      end
    end

    context "when there are no admin messages" do
      it "returns false" do
        expect(conversation.admin_messages_seen_by_client?).to be false
      end
    end
  end
end
