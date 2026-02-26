require 'rails_helper'

RSpec.describe "authors/show", type: :view do
  before(:each) do
    assign(:author, Author.create!(
      name: "Name",
      bio: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
  end
end
