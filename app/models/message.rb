class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :body, presence: true

  after_create_commit :broadcast_to_conversation
  after_create_commit :broadcast_conversation_list_update
  after_create_commit :broadcast_badges_and_toast
  after_create_commit :broadcast_seen_receipt_reset
  after_create_commit -> { conversation.touch }

  private

    def from_client?
      user_id == conversation.user_id
    end

    def broadcast_to_conversation
      broadcast_append_to(
        "conversation_#{conversation_id}",
        target: "messages-#{conversation_id}",
        partial: "messages/message",
        locals: { message: self }
      )
    end

    def broadcast_conversation_list_update
      broadcast_replace_to(
        "conversations_list",
        target: "conversation-#{conversation_id}",
        partial: "conversations/conversation",
        locals: { conversation: conversation.reload }
      )
    end

    def broadcast_seen_receipt_reset
      # When a new message arrives it's unread, so the sender's "Seen" receipt should clear.
      # The conversation model methods check the LAST message's read_at, which is now nil.
      if from_client?
        conversation.broadcast_client_seen_receipt  # client sent → clear client's "Seen"
      else
        conversation.broadcast_admin_seen_receipt   # admin sent → clear admin's "Seen"
      end
    end

    def broadcast_badges_and_toast
      if from_client?
        Conversation.broadcast_admin_badge
        Turbo::StreamsChannel.broadcast_append_to(
          "admin_toasts",
          target: "toast-container",
          partial: "shared/toast",
          locals: { toast_message: self }
        )
      else
        conversation.broadcast_client_badge
        Turbo::StreamsChannel.broadcast_append_to(
          "toast_user_#{conversation.user_id}",
          target: "toast-container",
          partial: "shared/toast",
          locals: { toast_message: self }
        )
      end
    end
end
