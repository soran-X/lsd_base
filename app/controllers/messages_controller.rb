class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    @message = @conversation.messages.build(
      user: Current.user,
      body: message_params[:body].to_s.strip
    )

    if @message.save
      mark_conversation_read
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  private

    def set_conversation
      if Current.user.admin?
        @conversation = Conversation.find(params[:conversation_id])
      else
        @conversation = Conversation.find_by!(id: params[:conversation_id], user: Current.user)
      end
    end

    def mark_conversation_read
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

    def message_params
      params.require(:message).permit(:body)
    end
end
