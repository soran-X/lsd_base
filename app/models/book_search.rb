class BookSearch < ApplicationRecord
  belongs_to :user

  PURGE_LIMIT = ENV.fetch("BOOK_SEARCH_LIMIT", 200).to_i

  after_create :purge_old_searches

  private

  def purge_old_searches
    keep_ids = user.book_searches.order(created_at: :desc).limit(PURGE_LIMIT).pluck(:id)
    user.book_searches.where.not(id: keep_ids).delete_all
  end
end
