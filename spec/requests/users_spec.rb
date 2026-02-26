require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:superadmin) { create(:user, :superadmin) }
  let(:admin)      { create(:user, :admin) }
  let(:client)     { create(:user, :client) }

  context "when not authenticated" do
    it "redirects to sign_in" do
      get users_path
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "when authenticated as client (insufficient role)" do
    before { sign_in_as(client) }

    it "redirects GET /users to root with alert" do
      get users_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when authenticated as admin" do
    before { sign_in_as(admin) }

    it "can list users" do
      get users_path
      expect(response).to have_http_status(:ok)
    end

    it "cannot edit a superadmin (higher hierarchy)" do
      get edit_user_path(superadmin)
      expect(response).to redirect_to(root_path)
    end

    it "can edit a client (lower hierarchy)" do
      get edit_user_path(client)
      expect(response).to have_http_status(:ok)
    end

    it "cannot assign superadmin role to a client" do
      superadmin_role = create(:role, :superadmin)
      patch user_path(client), params: { user: { role_id: superadmin_role.id } }
      expect(response).to redirect_to(users_path)
    end
  end

  context "when authenticated as superadmin" do
    before { sign_in_as(superadmin) }

    it "can edit any user" do
      get edit_user_path(admin)
      expect(response).to have_http_status(:ok)
    end

    it "can approve a user" do
      unapproved = create(:user, :unapproved)
      patch user_path(unapproved), params: { user: { approved: true } }
      expect(unapproved.reload.approved?).to be true
    end
  end
end
