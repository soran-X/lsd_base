require 'rails_helper'

RSpec.describe "Conversations", type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:client) { create(:user, :client) }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  context "when not authenticated" do
    it "redirects GET /conversations to sign_in" do
      get conversations_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects GET /conversations/mine to sign_in" do
      get mine_conversations_path
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "as admin" do
    before { sign_in_as(admin) }

    describe "GET /conversations" do
      it "returns 200" do
        get conversations_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /conversations/:id" do
      let(:conversation) { create(:conversation) }

      it "returns 200" do
        get conversation_path(conversation)
        expect(response).to have_http_status(:ok)
      end

      it "marks unread client messages as read" do
        msg = create(:message, conversation: conversation, user: conversation.user, read_at: nil)
        get conversation_path(conversation)
        expect(msg.reload.read_at).not_to be_nil
      end

      it "does not mark admin messages as read" do
        msg = create(:message, conversation: conversation, user: admin, read_at: nil)
        get conversation_path(conversation)
        expect(msg.reload.read_at).to be_nil
      end
    end

    describe "POST /conversations/:id/mark_read" do
      let(:conversation) { create(:conversation) }

      it "returns 204" do
        post mark_read_conversation_path(conversation)
        expect(response).to have_http_status(:no_content)
      end

      it "marks unread client messages as read" do
        msg = create(:message, conversation: conversation, user: conversation.user, read_at: nil)
        post mark_read_conversation_path(conversation)
        expect(msg.reload.read_at).not_to be_nil
      end
    end
  end

  context "as client" do
    before { sign_in_as(client) }

    describe "GET /conversations (admin-only)" do
      it "is not accessible" do
        get conversations_path
        expect(response).not_to have_http_status(:ok)
      end
    end

    describe "GET /conversations/mine" do
      it "returns 200" do
        get mine_conversations_path
        expect(response).to have_http_status(:ok)
      end

      it "creates a conversation for the client if none exists" do
        expect { get mine_conversations_path }.to change(Conversation, :count).by(1)
      end

      it "reuses an existing conversation" do
        create(:conversation, user: client)
        expect { get mine_conversations_path }.not_to change(Conversation, :count)
      end

      it "marks unread admin messages as read" do
        conversation = Conversation.find_or_create_by!(user: client)
        msg = create(:message, conversation: conversation, user: admin, read_at: nil)
        get mine_conversations_path
        expect(msg.reload.read_at).not_to be_nil
      end
    end

    describe "POST /conversations/mark_client_read" do
      it "returns 204" do
        post mark_client_read_conversations_path
        expect(response).to have_http_status(:no_content)
      end

      it "marks unread admin messages as read" do
        conversation = Conversation.find_or_create_by!(user: client)
        msg = create(:message, conversation: conversation, user: admin, read_at: nil)
        post mark_client_read_conversations_path
        expect(msg.reload.read_at).not_to be_nil
      end
    end
  end
end
