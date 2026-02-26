require 'rails_helper'

RSpec.describe SiteSetting, type: :model do
  subject { build(:site_setting) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_uniqueness_of(:key) }
  end

  describe ".[]" do
    it "returns the value for a key" do
      create(:site_setting, key: "test_key", value: "hello")
      expect(SiteSetting["test_key"]).to eq("hello")
    end

    it "returns nil for unknown key" do
      expect(SiteSetting["unknown_key"]).to be_nil
    end
  end

  describe ".allow_public_signup?" do
    it "returns true when value is 'true'" do
      create(:site_setting, key: "allow_public_signup", value: "true")
      expect(SiteSetting.allow_public_signup?).to be true
    end

    it "returns false when value is 'false'" do
      create(:site_setting, key: "allow_public_signup", value: "false")
      expect(SiteSetting.allow_public_signup?).to be false
    end

    it "returns false when setting does not exist" do
      expect(SiteSetting.allow_public_signup?).to be false
    end
  end
end
