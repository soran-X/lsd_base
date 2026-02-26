require 'rails_helper'

RSpec.describe RolePermission, type: :model do
  subject(:rp) { build(:role_permission) }

  describe "associations" do
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:permission) }
  end

  describe "validations" do
    let(:role)       { create(:role) }
    let(:permission) { create(:permission) }

    it "enforces uniqueness of role_id scoped to permission_id" do
      create(:role_permission, role: role, permission: permission)
      duplicate = build(:role_permission, role: role, permission: permission)
      expect(duplicate).not_to be_valid
    end
  end
end
