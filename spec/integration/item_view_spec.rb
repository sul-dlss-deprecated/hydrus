require 'spec_helper'

describe("Item view", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
  end

  it "If not logged in, should be redirected to the login page, then back to our intended page after logging in" do
    logout
    visit polymorphic_url(@hi)
    current_path.should == new_signin_path
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
      'Contributing Author', # label for actor
      'Frisbee, Hanna', # actor
      'Sponsor', # label for actor
      'US National Science Foundation, award SES-0751613', # actor
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
    click_button "Save"
    should_visit_view_page(@hi)
    page.should_not have_content('Related links')
    page.should_not have_content('story by Jennifer Ludden August 16, 2010')
  end


  it "should show the events in a history tab" do
    exp_content = [
      "How Couples Meet and Stay Together",
      'Event History for this Item',
      'Item created'
    ]
    login_as('archivist1')
    visit polymorphic_path([@hi, :events])
    current_path.should == polymorphic_path([@hi, :events])
    exp_content.each do |exp|
      page.should have_content(exp)
    end
  end
end
