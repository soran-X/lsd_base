require 'rails_helper'

RSpec.describe "scouts/edit", type: :view do
  let(:scout) {
    Scout.create!(
      name: "MyString",
      specialty: "MyString",
      notes: "MyText"
    )
  }

  before(:each) do
    assign(:scout, scout)
  end

  it "renders the edit scout form" do
    render

    assert_select "form[action=?][method=?]", scout_path(scout), "post" do
      assert_select "input[name=?]", "scout[name]"

      assert_select "input[name=?]", "scout[specialty]"

      assert_select "textarea[name=?]", "scout[notes]"
    end
  end
end
