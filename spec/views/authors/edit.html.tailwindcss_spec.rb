require 'rails_helper'

RSpec.describe "authors/edit", type: :view do
  let(:author) {
    Author.create!(
      name: "MyString",
      bio: "MyText"
    )
  }

  before(:each) do
    assign(:author, author)
  end

  it "renders the edit author form" do
    render

    assert_select "form[action=?][method=?]", author_path(author), "post" do
      assert_select "input[name=?]", "author[name]"

      assert_select "textarea[name=?]", "author[bio]"
    end
  end
end
