require 'spec_helper'

describe("Collection view", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @apo_druid = 'druid:oo000oo0002'
    @druid = 'druid:oo000oo0003'
    @druid_no_files='druid:oo000oo0004'    
    @hc    = Hydrus::Collection.find @druid
  end

  it "If not logged in, should be redirected to login page, then back to our intended page after logging in" do
    logout
    visit polymorphic_url(@hc)
    current_path.should == new_signin_path
    fill_in "Email", :with => 'archivist1@example.com' 
    fill_in "Password", :with => login_pw
    click_button "Sign in"
    current_path.should == polymorphic_path(@hc)    
  end

  it "Breadcrumbs should be displayed with home link and unlinked trucated collection name" do
    login_as_archivist1
    visit polymorphic_path(@hc)
    page.should have_selector("ul.breadcrumb li a", :text => "Home")
    page.should have_selector("ul.breadcrumb li", :text => "SSDS Social Science Data Co...")
  end
  
  it "should redirect to the collection page if the requested druid is a collection but is visited at the item page URL" do
    @bad_url = "/items/#{@druid}" # this is actually a collection druid
    login_as_archivist1
    visit @bad_url
    current_path.should == polymorphic_path(@hc)    
  end
  
  it "should show info from the Collection" do
    exp_content = [
      "SSDS Social Science Data Collection",
      "Description",
    ]
    login_as_archivist1
    visit polymorphic_path(@hc)
    current_path.should == polymorphic_path(@hc)
    exp_content.each do |exp|
      page.should have_content(exp)
    end
  end

  it "should show info from the Items of the Collection" do
    exp_content = [
      "How Couples Meet and Stay Together",
      "Ethnic Collective Action",
      'archivist3'
    ]
    login_as_archivist1
    visit polymorphic_path([@hc, :items])
    current_path.should == polymorphic_path([@hc, :items])
    coll_items = find('div#items')
    exp_content.each do |exp|
      coll_items.should have_content(exp)
    end
  end
  
  it "should show the events in a history tab" do
    exp_content = [
      "Collection created",
      "archivist1"
    ]
    login_as_archivist1
    visit polymorphic_path([@hc, :events])
    current_path.should == polymorphic_path([@hc, :events])
    coll_items = find('div.event-history')
    exp_content.each do |exp|
      coll_items.should have_content(exp)
    end
  end

  # it "should show some APO info" do
  #   exp_content = [
  #     "cc-by",
  #     "1 year",
  #   ]
  #   login_as_archivist1
  #   visit polymorphic_path(@hc)
  #   current_path.should == polymorphic_path(@hc)
  #   exp_content.each do |exp|
  #     page.should have_content(exp)
  #   end
  # end

end
