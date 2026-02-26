require 'rails_helper'

RSpec.describe "scouts/show", type: :view do
  before(:each) do
    assign(:scout, Scout.create!(
      name: "Name",
      specialty: "Specialty",
      notes: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Specialty/)
    expect(rendered).to match(/MyText/)
  end
end
