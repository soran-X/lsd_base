require 'rails_helper'

RSpec.describe "authors/index", type: :view do
  before(:each) do
    assign(:authors, [
      Author.create!(name: "Alice", bio: "Bio A"),
      Author.create!(name: "Bob",   bio: "Bio B")
    ])
  end

  it "renders a list of authors" do
    render
    expect(rendered).to include("Alice", "Bob")
    expect(rendered).to include("Bio A", "Bio B")
  end
end
