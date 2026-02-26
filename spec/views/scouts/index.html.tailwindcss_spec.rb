require 'rails_helper'

RSpec.describe "scouts/index", type: :view do
  before(:each) do
    assign(:scouts, [
      Scout.create!(name: "Scout A", specialty: "Defense", notes: "Notes A"),
      Scout.create!(name: "Scout B", specialty: "Offense", notes: "Notes B")
    ])
  end

  it "renders a list of scouts" do
    render
    expect(rendered).to include("Scout A", "Scout B")
    expect(rendered).to include("Defense", "Offense")
  end
end
