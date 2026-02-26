require 'rails_helper'

RSpec.describe "Messages", type: :request do
  let(:admin)        { create(:user, :admin) }
  let(:client)       { create(:user, :client) }
  let(:conversation) { create(:conversation, user: client) }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  context "when not authenticated" do
    it "redirects to sign_in" do
      post conversation_messages_path(conversation), params: { message: { body: "Hello" } }
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "as client (conversation owner)" do
    before { sign_in_as(client) }

    describe "POST /conversations/:id/messages" do
      it "creates a message and returns 204" do
        expect {
          post conversation_messages_path(conversation), params: { message: { body: "Hello" } }
        }.to change(Message, :count).by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "strips surrounding whitespace from the body" do
        post conversation_messages_path(conversation), params: { message: { body: "  hello  " } }
        expect(Message.last.body).to eq("hello")
      end

      it "returns 422 for a blank body" do
        post conversation_messages_path(conversation), params: { message: { body: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(Message.count).to eq(0)
      end

      it "cannot post to another user's conversation" do
        other = create(:conversation)
        post conversation_messages_path(other), params: { message: { body: "Hi" } }
        expect(response).not_to have_http_status(:no_content)
      end

      it "marks unread admin messages as read after sending" do
        admin_msg = create(:message, conversation: conversation, user: admin, read_at: nil)
        post conversation_messages_path(conversation), params: { message: { body: "reply" } }
        expect(admin_msg.reload.read_at).not_to be_nil
      end
    end
  end

  context "as admin" do
    before { sign_in_as(admin) }

    describe "POST /conversations/:id/messages" do
      it "creates a message and returns 204" do
        expect {
          post conversation_messages_path(conversation), params: { message: { body: "Hello client" } }
        }.to change(Message, :count).by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "marks unread client messages as read after replying" do
        client_msg = create(:message, conversation: conversation, user: client, read_at: nil)
        post conversation_messages_path(conversation), params: { message: { body: "reply" } }
        expect(client_msg.reload.read_at).not_to be_nil
      end

      it "can post to any conversation" do
        other = create(:conversation)
        expect {
          post conversation_messages_path(other), params: { message: { body: "Hi" } }
        }.to change(Message, :count).by(1)
      end
    end
  end
end
