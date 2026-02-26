require 'rails_helper'

RSpec.describe Author, type: :model do
  subject { build(:author) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "associations" do
    it { is_expected.to have_many(:books).dependent(:nullify) }
  end
end
