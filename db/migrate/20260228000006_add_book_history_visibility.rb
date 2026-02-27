class AddBookHistoryVisibility < ActiveRecord::Migration[8.1]
  def up
    SiteSetting.find_or_create_by!(key: "book_history_visibility") do |s|
      s.value = "staff"
    end
  end

  def down
    SiteSetting.find_by(key: "book_history_visibility")&.destroy
  end
end
