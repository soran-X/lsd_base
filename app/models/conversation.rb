class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  scope :recent, -> { order(updated_at: :desc) }

  # Messages from the client that admins haven't read yet
  def unread_for_admin
    messages.where(user: user, read_at: nil)
  end

  # Messages from admins that the client hasn't read yet
  def unread_for_client
    messages.where.not(user: user).where(read_at: nil)
  end

  # Count of conversations that have at least one unread client message
  def self.admin_unread_count
    joins(:messages)
      .where(messages: { read_at: nil })
      .where("messages.user_id = conversations.user_id")
      .distinct
      .count
  end

  def self.broadcast_admin_badge
    count = admin_unread_count
    Turbo::StreamsChannel.broadcast_replace_to(
      "conversations_badge",
      target: "conversations-badge",
      partial: "layouts/conversations_badge",
      locals: { count: count }
    )
  end

  def broadcast_client_badge
    count = unread_for_client.count
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_bubble_user_#{user_id}",
      target: "chat-bubble-badge",
      partial: "layouts/chat_bubble_badge",
      locals: { count: count }
    )
  end

  # True when the last message sent by admin has been read by the client
  def admin_messages_seen_by_client?
    last_admin_msg = messages.where.not(user: user).last
    last_admin_msg&.read_at.present?
  end

  # True when the last message sent by the client has been read by admin
  def client_messages_seen_by_admin?
    last_client_msg = messages.where(user: user).last
    last_client_msg&.read_at.present?
  end

  # Re-render this conversation's row in the admin left-panel list
  def broadcast_list_row_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "conversations_list",
      target: "conversation-#{id}",
      partial: "conversations/conversation",
      locals: { conversation: reload }
    )
  end

  # Broadcast the "Seen" receipt that admin sees (updates when client reads admin's messages)
  def broadcast_admin_seen_receipt
    seen      = admin_messages_seen_by_client?
    seen_at   = seen ? messages.where.not(user: user).where.not(read_at: nil).last&.read_at : nil
    Turbo::StreamsChannel.broadcast_replace_to(
      "conversation_#{id}",
      target: "admin-sent-seen-#{id}",
      partial: "conversations/seen_receipt",
      locals: { receipt_id: "admin-sent-seen-#{id}", seen: seen, seen_at: seen_at }
    )
  end

  # Broadcast the "Seen" receipt that client sees (updates when admin reads client's messages)
  def broadcast_client_seen_receipt
    seen      = client_messages_seen_by_admin?
    seen_at   = seen ? messages.where(user: user).where.not(read_at: nil).last&.read_at : nil
    Turbo::StreamsChannel.broadcast_replace_to(
      "conversation_#{id}",
      target: "client-sent-seen-#{id}",
      partial: "conversations/seen_receipt",
      locals: { receipt_id: "client-sent-seen-#{id}", seen: seen, seen_at: seen_at }
    )
  end
end
