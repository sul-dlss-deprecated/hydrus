require 'spec_helper'

describe("Home page", :type => :request, :integration => true) do

  before(:each) do
    @search_box  = '.search-query-form #search'
    @sdr         = "Stanford Digital Repository"
    @your_cs     = "Your Active Collections"
    @breadcrumbs = "ul.breadcrumb li a"
    @cc_button   = 'a.btn[href="/collections/new"]'
    @alert       = 'div.alert'
    @search_url  = '/catalog?q=&search_field=text&commit=search'
    @sign_in_msg = 'You must sign in'
  end

  it "if not logged in, should see intro text, but not other controls" do
    logout
    visit root_path
    expect(page).to have_content(@sdr)
    expect(page).not_to have_content(@your_cs)
    expect(page).to have_no_selector(@search_box)
    expect(page).not_to have_button(@cc_button)
  end

  it "if logged in, should see intro text, search box, and listing of collections" do
    login_as('archivist1')
    visit root_path
    expect(page).to have_content(@sdr)
    expect(page).to have_content(@your_cs)
    # page.should have_selector(@search_box)
  end

  it "dashboard: collections shown should vary by user and their roles" do
    exp = {
      'archivist1' => %w(oo000oo0003 oo000oo0004 oo000oo0010),
      'archivist2' => %w(oo000oo0010),
    }
    exp.each do |user, drus|
      login_as(user)
      visit root_path
      drus.each do |dru|
        xp = "//a[@href='/collections/druid:#{dru}']"
        expect(find('div.user-collections')).to have_xpath(xp)
      end
    end
  end

  it "search results should vary by user and their roles" do
    exp = {
      'archivist1' => 10,
      'archivist2' => 9,
    }
    exp.each do |user, exp_n|
      login_as(user)
      visit(@search_url)
      expect(find('.page_links')).to have_content("1 - #{exp_n} of #{exp_n}")
    end
  end

  it "breadcrumbs should not be displayed" do
    # Logged out
    logout
    visit root_path
    expect(page).not_to have_css(@breadcrumbs)
    # Logged in
    login_as('archivist1')
    visit root_path
    expect(page).not_to have_css(@breadcrumbs)
  end

  it "should show Create Collection button only if user has authority to create collections" do
    # No
    login_as('archivist3@example.com', login_pw)
    visit root_path
    expect(page).not_to have_selector(@cc_button)
    # Yes
    login_as('archivist1')
    visit root_path
    expect(page).to have_selector(@cc_button)
  end

  describe "search" do

    it "should not be able to issue direct-URL search if not logged in" do
      logout
      visit @search_url
      expect(current_path).to eq(new_user_session_path)
      expect(find(@alert)).to have_content(@sign_in_msg)
    end

  end

end
