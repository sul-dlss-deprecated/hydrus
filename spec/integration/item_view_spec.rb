require 'spec_helper'

describe("Item view", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
  end

  it "If not logged in, should be redirected to home page" do
    logout
    visit polymorphic_url(@hi)
    current_path.should == root_path
  end

  it "should redirect to the item page if the requested druid is an item but is visited at the collection page URL" do
    @bad_url = "/collections/#{@druid}" # this is actually an item druid
    login_as_archivist1
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
    login_as_archivist1
    visit polymorphic_path(@hi)
    current_path.should == polymorphic_path(@hi)
    exp_content.each do |exp|
      page.should have_content(exp)
    end
    
    # now let's delete the related items and the keywords, and go back to the
    # view page and make sure those fields don't show up or are listed
    should_visit_edit_page(@hi)
    click_link "remove_relatedItem_0" # remove both related items
    click_link "remove_relatedItem_0"        
    fill_in "hydrus_item_keywords", :with => " "
    click_button "Save"
    should_visit_view_page(@hi)
    page.should have_content('Related links')
    page.should have_content('Keywords')
    page.should have_content('story by Jennifer Ludden August 16, 2010') # relatedItem
  end


  it "should show the events in a history tab" do
    exp_content = [
      "SSDS Social Science Data Collection",
      "How Couples Meet and Stay Together",
      'cardinal',
    ]
    login_as_archivist1
    visit polymorphic_path([@hi, :events])
    current_path.should == polymorphic_path([@hi, :events])
    exp_content.each do |exp|
      page.should have_content(exp)
    end
  end
end
