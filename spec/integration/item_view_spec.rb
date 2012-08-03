require 'spec_helper'

describe("Item view", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
  end

  it "If not logged in, should be redirected to sign-in page" do
    logout
    visit polymorphic_url(@hi)
    current_path.should == new_user_session_path
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
      'Related links', # relatedItem label
      'Keywords', # keywords label
      'story by Jennifer Ludden August 16, 2010', # relatedItem title
      'pinocchio.htm', # file
    ]
    login_as_archivist1
    visit polymorphic_path(@hi)
    current_path.should == polymorphic_path(@hi)
    exp_content.each do |exp|
      page.should have_content(exp)
    end
    
    # now let's delete the related items, contact email and the keywords, and go back to the view page and make sure those fields don't show up or are listed as "not specified" as required
    visit edit_polymorphic_path(@hi)
    click_link "remove_relatedItem_0" # remove both related items
    click_link "remove_relatedItem_0"        
    fill_in "hydrus_item_keywords", :with => " "
    fill_in "hydrus_item_contact", :with => " "
    click_button "Save"    
    visit polymorphic_path(@hi)
    page.should_not have_content('Related links')
    page.should_not have_content('Keywords')
    page.should_not have_content('story by Jennifer Ludden August 16, 2010') # relatedItem title
    page.should have_content('not specified') # for contact
    
  end

  it "some of the expected info is displayed in the Item status box" do
    exp_content = [
      @hi.item_depositor_name,
    ]
    login_as_archivist1
    visit polymorphic_path(@hi)
    current_path.should == polymorphic_path(@hi)
    item_status_box = find('div.item-status')
    exp_content.each do |exp|
      item_status_box.should have_content(exp)
    end
  end

end
