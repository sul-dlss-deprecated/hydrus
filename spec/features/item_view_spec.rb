require 'spec_helper'

describe("Item view", :type => :request, :integration => true) do

  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
  end

  it "If not logged in, should be redirected to the login page, then back to our intended page after logging in" do
    logout
    visit "/items/#{@druid}"
    current_path.should == new_user_session_path
    fill_in "Email", :with => 'archivist1@example.com'
    fill_in "Password", :with => login_pw
    click_button "Sign in"
    current_path.should == polymorphic_path(@hi)
  end

  it "Breadcrumbs should be displayed with home link, linked trucated collection name, and unlinked item name with state" do
    login_as('archivist1')
    visit polymorphic_path(@hi)
    page.should have_selector("ul.breadcrumb li a", :text => "Home")
    page.should have_selector("ul.breadcrumb li a", :text => "SSDS Social Science Data Co...")
    page.should have_selector("ul.breadcrumb li", :text => "How Couples Meet and Stay T... (published)")
  end

  it "should redirect to the item page if the requested druid is an item but is visited at the collection page URL" do
    @bad_url = "/collections/#{@druid}" # this is actually an item druid
    login_as('archivist1')
    visit @bad_url
    current_path.should == polymorphic_path(@hi)
  end

  it "Some of the expected info is displayed, and disappers if blank" do
    exp_content = [
      'archivist1@example.com', # contact email
      "How Couples Meet and Stay Together", # title
      "The story of Pinocchio", #abstract
      @druid,
      'Contributing author', # label for contributor
      'Frisbee, Hanna', # contributor
      'Sponsor', # label for contributor
      'US National Science Foundation, award SES-0751613', # contributor
      'wooden boys', # keyword
      'Keywords', # keywords label
      'pinocchio.htm', # file
    ]
    login_as('archivist1')
    visit polymorphic_path(@hi)
    current_path.should == polymorphic_path(@hi)
    exp_content.each do |exp|
      page.should have_content(exp)
    end

    # Now let's delete the related items and go back to the
    # view page and make sure those fields don't show up.
    should_visit_edit_page(@hi)
    click_link "remove_relatedItem_0" # remove both related items
    click_link "remove_relatedItem_0"
    click_button "save_nojs"
    should_visit_view_page(@hi)
    page.should_not have_content('Related links')
    page.should_not have_content('story by Jennifer Ludden August 16, 2010')
  end

  it "should apply the active class to the active tab" do
    login_as('archivist1')
    tests = {
      "Published Version" => @hi,
      "History"           => [@hi, :events],
    }
    tests.each do |exp, arg|
      should_visit_view_page(arg)
      es = all('ul.nav li.active')
      es.size.should == 1
      es.first.should have_content(exp)
    end
  end

  it "should show the events in a history tab" do
    exp_content = [
      "How Couples Meet and Stay Together",
      'Event History for this Item',
      'Item created'
    ]
    login_as('archivist1')
    should_visit_view_page([@hi, :events])
    exp_content.each do |exp|
      page.should have_content(exp)
    end
  end

  it "redirect_if_not_correct_object_type()" do
    login_as('archivist1')
    # View item URL with a collection PID.
    visit '/items/druid:oo000oo0003'
    current_path.should == '/collections/druid:oo000oo0003'
    # Edit collection URL with an item PID.
    visit '/collections/druid:oo000oo0001/edit'
    current_path.should == '/items/druid:oo000oo0001/edit'
  end

  it "can exercise purl_page_ready?" do
    # Our fixture object is not on PURL.
    @hi.purl_page_ready?.should == false
    # But this pid does exist on purl-test.
    @hi.stub(:purl_url).and_return('http://purl-test.stanford.edu/pf182cd5962.xml')
    @hi.purl_page_ready?.should == true
  end

end
