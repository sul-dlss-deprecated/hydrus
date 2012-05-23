require 'spec_helper'

describe("Home page", :type => :request) do

  it "Some of the expected info is displayed" do
    visit root_path
    page.should have_content("Stanford Digital Repository")
    page.should have_content("Hydrus")
    page.should_not have_content("override")
  end

end
