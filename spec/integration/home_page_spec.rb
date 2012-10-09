require 'spec_helper'

describe("Home page", :type => :request, :integration => true) do

  before(:each) do
    @search_box  = 'select.search_field + input.submit'
    @sdr         = "Stanford Digital Repository"
    @your_cs     = "Your Active Collections"
    @breadcrumbs = "ul.breadcrumb li a"
    @cc_button   = 'a.btn [href="/collections/new"]'
    @alert       = 'div.alert'
    @search_url  = '/catalog?q=&search_field=text&commit=search'
    @sign_in_msg = 'You must sign in'
  end

  it "if not logged in, should see intro text, but not other controls" do
    logout
    visit root_path
    page.should have_content(@sdr)
    page.should_not have_content(@your_cs)
    page.should have_no_selector(@search_box)
    page.should_not have_button(@cc_button)
  end

  it "if logged in, should see intro text, search box, and listing of collections" do
    login_as_archivist1
    visit root_path
    page.should have_content(@sdr)
    page.should have_content(@your_cs)
    page.should have_selector(@search_box)
  end

  it "breadcrumbs should not be displayed" do
    # Logged out
    logout
    visit root_path
    page.should_not have_css(@breadcrumbs)
    # Logged in
    login_as_archivist1
    visit root_path
    page.should_not have_css(@breadcrumbs)
  end

  it "should show Create Collection button only if user has authority to create collections" do
    # No
    login_as('ggreen', login_pw)
    visit root_path
    page.should_not have_selector(@cc_button)
    # Yes
    login_as_archivist1
    visit root_path
    page.should have_selector(@cc_button)
  end

  describe "search" do

    it "should not be able to issue direct-URL search if not logged in" do
      logout
      visit @search_url
      current_path.should == new_user_session_path
      find(@alert).should have_content(@sign_in_msg)
    end

  end

end
