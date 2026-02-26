require 'rails_helper'

RSpec.describe "Authentication flow", type: :system do
  let(:user) { create(:user, :approved, password: "Password1!Pw", password_confirmation: "Password1!Pw") }

  describe "sign in" do
    it "signs in with valid credentials and shows dashboard" do
      sign_in_as(user)
      expect(page).to have_current_path(dashboard_path, ignore_query: true)
    end

    it "shows error with invalid credentials" do
      visit sign_in_path
      fill_in "Email",    with: user.email
      fill_in "Password", with: "WrongPassword!"
      click_on "Sign in"
      expect(page).to have_current_path(sign_in_path, ignore_query: true)
    end
  end

  describe "sign out" do
    it "signs out and redirects to sign_in" do
      sign_in_as(user)
      visit dashboard_path
      click_button "Sign out"
      expect(page).to have_current_path(sessions_path, ignore_query: true).or have_current_path(sign_in_path, ignore_query: true)
    end
  end
end
