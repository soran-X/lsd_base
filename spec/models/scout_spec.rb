require 'rails_helper'

RSpec.describe Scout, type: :model do
  subject { build(:scout) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end
end
