require 'rails_helper'

RSpec.describe Permission, type: :model do
  subject(:permission) { build(:permission) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:resource) }
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_uniqueness_of(:resource).scoped_to(:action) }
  end

  describe "associations" do
    it { is_expected.to have_many(:role_permissions).dependent(:destroy) }
    it { is_expected.to have_many(:roles).through(:role_permissions) }
  end

  describe "ALL_PERMISSIONS constant" do
    it "includes books resource" do
      expect(Permission::ALL_PERMISSIONS).to have_key("books")
    end

    it "includes roles resource" do
      expect(Permission::ALL_PERMISSIONS).to have_key("roles")
    end

    it "books has index and show actions" do
      expect(Permission::ALL_PERMISSIONS["books"]).to include("index", "show")
    end
  end
end
