require 'rails_helper'

RSpec.describe "scouts/new", type: :view do
  before(:each) do
    assign(:scout, Scout.new(
      name: "MyString",
      specialty: "MyString",
      notes: "MyText"
    ))
  end

  it "renders new scout form" do
    render

    assert_select "form[action=?][method=?]", scouts_path, "post" do
      assert_select "input[name=?]", "scout[name]"

      assert_select "input[name=?]", "scout[specialty]"

      assert_select "textarea[name=?]", "scout[notes]"
    end
  end
end
