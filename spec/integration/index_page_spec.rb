require 'spec_helper'

describe("Search page", :type => :request, :integration => true) do

  it "Some results should appear for archivist1 user for default search" do
    visit root_path

    login_as_archivist1
    click_button("search")

    page.should have_content("Object ID")
    page.should have_content("druid:oo000oo0001")
    page.should have_content("Hydrus_Item")
    page.should have_content("druid:oo000oo0003")
    page.should have_content("Hydrus_Collection")
  end

end
