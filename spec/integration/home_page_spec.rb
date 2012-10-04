require 'spec_helper'

describe("Home page", :type => :request, :integration => true) do

  it "Some of the expected info is displayed" do
    visit root_path
    page.should have_content("Stanford Digital Repository")
    page.should have_content("SDR")
    page.should_not have_content("active collections")
  end

  it "Breadcrumbs should not be displayed" do
    visit root_path
    page.should_not have_css("ul.breadcrumb li a")
  end

end
