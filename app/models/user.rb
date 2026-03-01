class User < ApplicationRecord
  include Discard::Model
  include PgSearch::Model

  pg_search_scope :search_by_name,
    against: { first_name: "A", last_name: "A", email: "B" },
    using: { tsearch: { prefix: true, dictionary: "simple" } }

  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  generates_token_for :invitation, expires_in: 7.days do
    password_salt.last(10)
  end

  belongs_to :role, optional: true
  has_many :sessions, dependent: :destroy
  has_many :recovery_codes, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
  has_many :book_searches, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_validation on: :create do
    self.otp_secret = ROTP::Base32.random if otp_secret.blank?
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  after_create_commit -> { broadcast_pending_badge unless approved? }
  after_update_commit :broadcast_pending_badge, if: :saved_change_to_approved?

  def approved? = approved
  def oauth_user? = provider.present? && uid.present?

  def full_name
    [ first_name, last_name ].compact_blank.join(" ").presence
  end

  def display_name
    full_name || email.split("@").first
  end

  def initials
    if first_name.present? || last_name.present?
      [ first_name&.first, last_name&.first ].compact.join.upcase
    else
      email.first.upcase
    end
  end

  def hierarchy_level
    role&.hierarchy_level.to_i
  end

  def superadmin? = hierarchy_level >= 100
  def admin?      = hierarchy_level >= 50
  def client?     = hierarchy_level >= 10

  def can?(action, resource)
    role&.can?(action, resource) || false
  end

  # Can this user manage (view/edit) the target user?
  def can_manage?(target_user)
    hierarchy_level >= target_user.hierarchy_level
  end

  # Can this user assign a given role?
  def can_assign_role?(role)
    return false if role.nil?
    hierarchy_level >= role.hierarchy_level
  end

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email      = auth.info.email      if user.email.blank?
    user.first_name = auth.info.first_name if user.first_name.blank?
    user.last_name  = auth.info.last_name  if user.last_name.blank?
    user.verified   = true
    user.password   = SecureRandom.base58(24) if user.new_record?
    user
  end

  private

    def broadcast_pending_badge
      count = User.where(approved: false).count
      Turbo::StreamsChannel.broadcast_replace_to(
        "pending_users_badge",
        target: "pending-users-badge",
        partial: "layouts/pending_badge",
        locals: { count: count }
      )
    end
end
