require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to have_secure_password }
  end

  describe "associations" do
    it { is_expected.to belong_to(:role).optional }
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:recovery_codes).dependent(:destroy) }
  end

  describe "approval state" do
    it "defaults to unapproved" do
      u = create(:user)
      expect(u.approved?).to be false
    end

    it "can be approved" do
      u = create(:user, :approved)
      expect(u.approved?).to be true
    end
  end

  describe "#hierarchy_level" do
    it "returns 0 when user has no role" do
      u = build(:user, role: nil)
      expect(u.hierarchy_level).to eq(0)
    end

    it "delegates to role's hierarchy_level" do
      role = build(:role, hierarchy_level: 50)
      u    = build(:user, role: role)
      expect(u.hierarchy_level).to eq(50)
    end
  end

  describe "#can_manage?" do
    let(:superadmin_role) { create(:role, :superadmin) }
    let(:admin_role)      { create(:role, :admin) }
    let(:client_role)     { create(:role, :client) }

    let(:superadmin) { create(:user, :approved, role: superadmin_role) }
    let(:admin)      { create(:user, :approved, role: admin_role) }
    let(:client)     { create(:user, :approved, role: client_role) }

    it "superadmin can manage admin" do
      expect(superadmin.can_manage?(admin)).to be true
    end

    it "admin cannot manage superadmin" do
      expect(admin.can_manage?(superadmin)).to be false
    end

    it "admin can manage client" do
      expect(admin.can_manage?(client)).to be true
    end
  end

  describe "#can_assign_role?" do
    let(:superadmin_role) { create(:role, :superadmin) }
    let(:admin_role)      { create(:role, :admin) }
    let(:client_role)     { create(:role, :client) }

    let(:superadmin_user) { create(:user, :approved, role: superadmin_role) }
    let(:admin_user)      { create(:user, :approved, role: admin_role) }

    it "superadmin can assign any role" do
      expect(superadmin_user.can_assign_role?(superadmin_role)).to be true
      expect(superadmin_user.can_assign_role?(client_role)).to be true
    end

    it "admin cannot assign superadmin role" do
      expect(admin_user.can_assign_role?(superadmin_role)).to be false
    end

    it "admin can assign client role" do
      expect(admin_user.can_assign_role?(client_role)).to be true
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "uid-123",
        info: OmniAuth::AuthHash::InfoHash.new(email: "oauth@example.com")
      )
    end

    it "builds a user from OAuth hash" do
      user = User.from_omniauth(auth)
      expect(user.provider).to eq("google_oauth2")
      expect(user.uid).to eq("uid-123")
      expect(user.email).to eq("oauth@example.com")
      expect(user.verified).to be true
    end

    it "finds existing user by provider/uid" do
      existing = create(:user, :oauth_user, provider: "google_oauth2", uid: "uid-123")
      found    = User.from_omniauth(auth)
      expect(found.id).to eq(existing.id)
    end
  end
end
