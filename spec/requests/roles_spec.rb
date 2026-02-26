require 'rails_helper'

RSpec.describe "Roles", type: :request do
  let(:superadmin) { create(:user, :superadmin) }
  let(:admin)      { create(:user, :admin) }
  let(:client)     { create(:user, :client) }

  context "when authenticated as client" do
    before { sign_in_as(client) }

    it "redirects GET /roles to root" do
      get roles_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "when authenticated as admin" do
    before { sign_in_as(admin) }

    it "can list roles" do
      get roles_path
      expect(response).to have_http_status(:ok)
    end

    it "cannot create a role with higher hierarchy" do
      post roles_path, params: { role: { name: "Uber", hierarchy_level: 100 } }
      expect(response).to redirect_to(roles_path)
    end

    it "can create a role with equal or lower hierarchy" do
      expect {
        post roles_path, params: { role: { name: "SubAdmin", hierarchy_level: 40 } }
      }.to change(Role, :count).by(1)
    end
  end

  context "when authenticated as superadmin" do
    before { sign_in_as(superadmin) }

    it "can create any role" do
      expect {
        post roles_path, params: { role: { name: "NewRole", hierarchy_level: 99 } }
      }.to change(Role, :count).by(1)
    end

    it "can delete a role" do
      role = create(:role, :client)
      expect { delete role_path(role) }.to change(Role, :count).by(-1)
    end
  end
end
