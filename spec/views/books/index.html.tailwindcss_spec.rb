require 'rails_helper'

RSpec.describe "books/index", type: :view do
  before(:each) do
    assign(:books, [
      Book.create!(title: "Book One", description: "Desc A"),
      Book.create!(title: "Book Two", description: "Desc B")
    ])
  end

  it "renders a list of books" do
    render
    expect(rendered).to include("Book One", "Book Two")
  end
end
