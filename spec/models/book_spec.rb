require 'rails_helper'

RSpec.describe Book, type: :model do
  subject { build(:book) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:author).optional }
  end
end
