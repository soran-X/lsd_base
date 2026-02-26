class ConversationsController < ApplicationController
  def index
    require_admin!
    @conversations = Conversation.includes(:user, :messages).recent
  end

  def show
    @conversation = find_conversation
    mark_messages_read
  end

  # Client-facing: find or create their conversation, then render show
  def mine
    @conversation = Conversation.find_or_create_by!(user: Current.user)
    mark_messages_read
    render :show
  end

  # Client-facing: called via fetch whenever the client interacts with the chat window
  def mark_client_read
    @conversation = Conversation.find_or_create_by!(user: Current.user)
    mark_messages_read
    head :no_content
  end

  # Admin-facing: called via fetch when admin focuses/hovers the conversation panel
  def mark_read
    @conversation = find_conversation
    mark_messages_read
    head :no_content
  end

  private

    def find_conversation
      if Current.user.admin?
        Conversation.find(params[:id])
      else
        Conversation.find_by!(id: params[:id], user: Current.user)
      end
    end

    def mark_messages_read
      if Current.user.admin?
        @conversation.unread_for_admin.update_all(read_at: Time.current)
        Conversation.broadcast_admin_badge
        @conversation.broadcast_list_row_update
        @conversation.broadcast_client_seen_receipt
      else
        @conversation.unread_for_client.update_all(read_at: Time.current)
        @conversation.broadcast_client_badge
        @conversation.broadcast_admin_seen_receipt
      end
    end
end
