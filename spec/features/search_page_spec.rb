require 'spec_helper'

describe("Search page", :type => :request, :integration => true) do

  it "Some results should appear for archivist1 user for default search" do
    visit root_path
    login_as('archivist1')
    click_button("search")
    docs = find 'div#documents'
    docs.should have_content 'How Couples Meet'
    docs.should have_content 'SSDS Social Science Data Collection'
  end

end
