require 'rails_helper'

RSpec.describe Role, type: :model do
  subject(:role) { build(:role) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:hierarchy_level) }
    it { is_expected.to validate_numericality_of(:hierarchy_level).only_integer.is_greater_than(0) }
  end

  describe "associations" do
    it { is_expected.to have_many(:users).dependent(:nullify) }
  end

  describe ".assignable_by" do
    # Use unique names to avoid conflicts with other describe blocks
    let(:superadmin_role) { create(:role, name: "SuperAdmin-AS", hierarchy_level: 100) }
    let(:admin_role)      { create(:role, name: "Admin-AS",      hierarchy_level: 50)  }
    let(:client_role)     { create(:role, name: "Client-AS",     hierarchy_level: 10)  }

    before { superadmin_role; admin_role; client_role }

    it "returns all roles for superadmin" do
      expect(Role.assignable_by(superadmin_role)).to include(superadmin_role, admin_role, client_role)
    end

    it "returns only roles at or below admin level" do
      result = Role.assignable_by(admin_role)
      expect(result).to include(admin_role, client_role)
      expect(result).not_to include(superadmin_role)
    end

    it "returns empty when actor_role is nil" do
      expect(Role.assignable_by(nil)).to be_empty
    end
  end

  describe "hierarchy predicate methods" do
    it "#superadmin? returns true for hierarchy_level >= 100" do
      role = build(:role, hierarchy_level: 100)
      expect(role.superadmin?).to be true
    end

    it "#admin? returns true for hierarchy_level >= 50" do
      role = build(:role, hierarchy_level: 50)
      expect(role.admin?).to be true
    end

    it "#client? returns true for hierarchy_level >= 10" do
      role = build(:role, hierarchy_level: 10)
      expect(role.client?).to be true
    end
  end

  describe ".ordered" do
    it "returns roles ordered by hierarchy_level descending" do
      client = create(:role, name: "Client-ORD",    hierarchy_level: 10)
      admin  = create(:role, name: "Admin-ORD",     hierarchy_level: 50)
      super_ = create(:role, name: "SuperAdmin-ORD", hierarchy_level: 100)

      ordered = Role.where(id: [ client.id, admin.id, super_.id ]).ordered
      expect(ordered.to_a).to eq([ super_, admin, client ])
    end
  end
end
