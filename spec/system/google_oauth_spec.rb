require 'rails_helper'

RSpec.describe "Google OAuth flow", type: :system do
  before do
    mock_google_oauth(email: "google@example.com", uid: "google-uid-999")
  end

  describe "OAuth sign-in" do
    it "redirects unapproved OAuth users away from dashboard" do
      visit "/auth/google_oauth2"
      expect(page).not_to have_current_path(dashboard_path, ignore_query: true)
    end

    it "signs in approved OAuth user" do
      create(:user, :oauth_user, :approved,
             provider: "google_oauth2", uid: "google-uid-999",
             email: "google@example.com")
      visit "/auth/google_oauth2"
      expect(page).to have_current_path(dashboard_path, ignore_query: true)
    end
  end
end
