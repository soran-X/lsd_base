class AddBookListViewSetting < ActiveRecord::Migration[8.1]
  def up
    SiteSetting.find_or_create_by!(key: "book_list_view") do |s|
      s.value = "table"
    end
  end

  def down
    SiteSetting.find_by(key: "book_list_view")&.destroy
  end
end
