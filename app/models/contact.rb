class Contact < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  has_many :book_contacts, dependent: :destroy
  has_many :books, through: :book_contacts

  # ── Validations ───────────────────────────────────────────────────────────
  validates :first_name, :last_name, presence: true

  def display_name = "#{last_name}, #{first_name}"
  def to_s = display_name
end
