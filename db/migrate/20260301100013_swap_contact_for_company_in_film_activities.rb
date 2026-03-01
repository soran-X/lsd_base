class SwapContactForCompanyInFilmActivities < ActiveRecord::Migration[8.1]
  def change
    remove_reference :film_activities, :contact, foreign_key: true
    add_reference    :film_activities, :company, null: true, foreign_key: true
  end
end
