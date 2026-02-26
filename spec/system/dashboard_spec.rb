require 'rails_helper'

RSpec.describe "Dashboard sidebar", type: :system do
  describe "as a client (hierarchy_level 10)" do
    let(:user) { create(:user, :client, :approved) }

    before { sign_in_as(user) }

    it "shows Books, Authors, Scouts links" do
      visit dashboard_path
      expect(page).to have_link("Books")
      expect(page).to have_link("Authors")
      expect(page).to have_link("Scouts")
    end

    it "does not show Roles or Site Settings links" do
      visit dashboard_path
      expect(page).not_to have_link("Roles")
      expect(page).not_to have_link("Site Settings")
    end

    it "shows user display name in sidebar footer" do
      visit dashboard_path
      expect(page).to have_content(user.display_name)
    end
  end

  describe "as an admin (hierarchy_level 50)" do
    let(:user) { create(:user, :admin, :approved) }

    before { sign_in_as(user) }

    it "shows Roles and Users links" do
      visit dashboard_path
      expect(page).to have_link("Roles")
      expect(page).to have_link("Users")
    end

    it "shows Site Settings link" do
      visit dashboard_path
      expect(page).to have_link("Site Settings")
    end
  end

  describe "as a superadmin (hierarchy_level 100)" do
    let(:user) { create(:user, :superadmin, :approved) }

    before { sign_in_as(user) }

    it "shows all sidebar links" do
      visit dashboard_path
      expect(page).to have_link("Dashboard")
      expect(page).to have_link("Books")
      expect(page).to have_link("Authors")
      expect(page).to have_link("Scouts")
      expect(page).to have_link("Users")
      expect(page).to have_link("Roles")
      expect(page).to have_link("Site Settings")
    end
  end
end
