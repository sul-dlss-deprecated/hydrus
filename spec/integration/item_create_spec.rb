require 'spec_helper'

describe("Item create", :type => :request, :integration => true) do

  before(:all) do
    @notice = "Your changes have been saved."
    @hc_druid = 'druid:oo000oo0003'
    @edit_path_regex = Regexp.new('/items/(druid:\w{11})/edit')
    # Need to mint an actual druid in order to pass validation.
    @prev_mint_ids = Dor::Config.configure.suri.mint_ids
    Dor::Config.configure.suri.mint_ids = true
  end

  after(:all) do
    # Restore mint_ids setting.
    Dor::Config.configure.suri.mint_ids = @prev_mint_ids
  end
  
  it "should have a non-js select list for depositing items into collections" do
    login_as_archivist1
    visit hydrus_collection_path(:id=>@hc_druid)
    select "item", :from => "collection"
    click_button "Add"
    current_path.should_not == hydrus_collection_path(:id=>@hc_druid)
    current_path.should =~ @edit_path_regex
  end
  
  it "should be able to create a new Item, with expected datastreams" do
    # Login, go to new Item page, and store the druid of the new Item.
    login_as_archivist1
    visit new_hydrus_item_path(:collection => @hc_druid)
    current_path.should =~ @edit_path_regex
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    click_button "Add Person"
    fill_in "Title of item", :with => 'title_foo'
    fill_in "hydrus_item_person_0", :with => 'person_foo'
    fill_in "Abstract", :with => 'abstract_foo'
    click_button "Save"
    page.should have_content(@notice)
    # Get Item out of fedora and confirm that our edits were persisted.
    item = Hydrus::Item.find(druid)
    item.title.should == 'title_foo'
    item.person.first.should == 'person_foo'
    item.abstract.should == 'abstract_foo'
    item.should be_instance_of Hydrus::Item
    # Check workflow of Item.
    wf_nodes = item.workflows.find_by_terms(:workflow)
    wf_nodes.size.should == 1
    wf_nodes.first[:id].should == 'hydrusAssemblyWF'
    # Check identityMetadata of Item.
    item.identityMetadata.tag.should include("Hydrus : dataset", "Project : Hydrus")
    # Check person roles of the Item.
    item.person_roles.should == { "hydrus-item-depositor" => Set.new(["archivist1"]) }
    # Check events.
    exp = [
      /\AItem created/,
      /\AItem modified/, # Visibility. Do not expect this. Refactor of rightsMD might fix.
      /\AItem modified/,
    ]
    es = item.get_hydrus_events
    es.size.should == exp.size
    es[0...exp.size].zip(exp).each do |e, exp|
      e.text.should =~ exp
      e.who.should == 'archivist1'
      e.type.should == 'hydrus'
    end
  end

  it "should be able to access create-new-Item screen via the Collection view page" do
    login_as_archivist1
    collection = Hydrus::Collection.find(@hc_druid)
    visit polymorphic_path(collection)
    click_link('item')
    current_path.should =~ @edit_path_regex
  end

  it "should be able to create a new Item, publish, etc" do
    ni = hash2struct(
      :title    => 'title_foo',
      :abstract => 'abstract_foo',
      :contact  => 'ozzy@hell.com',
      :reason   => 'Idiota',
      :person   => 'person_foo',
    )
    publish_button    = "Submit for Approval"
    approve_button    = "Approve Item"
    disapprove_button = "Return Item"
    # Force Items to receive human approval.
    coll = Hydrus::Collection.find(@hc_druid)
    coll.requires_human_approval = 'yes'
    coll.save
    # Login, go to new Item page, and store the druid of the new Item.
    login_as_archivist1
    visit new_hydrus_item_path(:collection => @hc_druid)
    current_path.should =~ @edit_path_regex
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    click_button "Add Person"
    fill_in "hydrus_item_person_0", :with => ni.person
    fill_in "Title of item", :with => ni.title
    click_button "Save"
    page.should have_content(@notice)
    # The view page should display some validation error messages, and should not
    # offer the Publish button.
    div_cs = find("div.collection-actions")
    div_cs.should_not have_button(publish_button)
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    item.is_publishable.should == false
    item.is_published.should == false
    item.is_approved.should == false
    item.is_disapproved.should == false
    item.is_destroyable.should == true
    item.accepted_terms_of_deposit.should == "false"
    item.valid?.should == true  # Because unpublished, so validation is limited.
    # accept terms of deposit (hard to do via the UI since a pop-up window is involved, so let's exercise the method directly)
    item.accept_terms_of_deposit('archivist1')
    item.save
    # Go back to edit page and fill in required elements.
    should_visit_edit_page(item)
    check "release_settings"
    fill_in "hydrus_item_abstract", :with => ni.abstract
    fill_in "hydrus_item_contact",  :with => ni.contact
    f = Hydrus::ObjectFile.new
    f.pid = druid
    f.file = Tempfile.new('mock_HydrusObjectFile_')
    f.save
    click_button "Save"
    page.should have_content(@notice)
    # The view page should now offer the Publish button.
    div_cs = find("div.collection-actions")
    div_cs.should have_button(publish_button)
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    item.is_publishable.should == true
    item.is_published.should == false
    item.is_approved.should == false
    item.is_disapproved.should == false
    item.is_destroyable.should == true
    item.valid?.should == true
    # Publish the Item.
    click_button(publish_button)
    page.should have_content(@notice)
    # The view page should not offer the Publish button.
    div_cs = find("div.collection-actions")
    div_cs.should_not have_button(publish_button)
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    item.is_publishable.should == true
    item.is_published.should == true
    item.is_approved.should == false
    item.is_disapproved.should == false
    item.is_destroyable.should == false
    item.valid?.should == true
    # Return to edit page, and try to save Item with an empty title.
    click_link "Edit Draft (only for dev)"
    fill_in "hydrus_item_title", :with => ''
    click_button "Save"
    page.should_not have_content(@notice)
    find('div.alert').should have_content('Title cannot be blank')
    # Fill in the title and save.
    fill_in "hydrus_item_title", :with => ni.title
    click_button "Save"
    page.should have_content(@notice)
    # Disapprove the Item.
    fill_in "hydrus_item_approve_reason", :with => ni.reason
    click_button(disapprove_button)
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    item.is_publishable.should == true
    item.is_published.should == true
    item.is_approved.should == false
    item.is_disapproved.should == true
    item.is_destroyable.should == false
    item.valid?.should == true
    item.disapproval_reason.should == ni.reason
    # Approve the Item.
    click_button(approve_button)
    page.should have_content(@notice)
    # The view page should not offer the Publish, Approve, or Disapprove buttons.
    div_cs = find("div.collection-actions")
    div_cs.should_not have_button(publish_button)
    div_cs.should_not have_button(approve_button)
    div_cs.should_not have_button(disapprove_button)
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    item.is_publishable.should == true
    item.is_published.should == true
    item.is_approved.should == true
    item.is_disapproved.should == false
    item.is_destroyable.should == false
    item.valid?.should == true
    item.disapproval_reason.should == nil
    # Check events.
    exp = [
      /\AItem created/,
      /\AItem modified/, # Visibility. Do not expect this. Refactor of rightsMD might fix.
      /\AItem modified/,
      /\ATerms of deposit accepted/,
      /\AItem modified/,
      /\AItem published/,
      /\AItem disapproved/,
      /\AItem approved/,
    ]
    es = item.get_hydrus_events
    es[0...exp.size].zip(exp).each { |e, exp| e.text.should =~ exp  }
  end
  
  describe "terms of acceptance for an existing item" do

    subject { Hydrus::Item.find('druid:oo000oo0001') }
    
    it "should indicate if the item has had terms accepted already" do
      subject.accepted_terms_of_deposit.should == "true"
      subject.terms_of_deposit_accepted?.should == true
    end

    it "should indicate the users who have accepted the terms of deposit for this collection in a hash and should returns dates accepted" do
      users=subject.collection.users_accepted_terms_of_deposit
      users.class.should == Hash
      users.keys.include?('cardinal').should == true
      users['cardinal'].should == '2011-09-02 01:02:32 -0700'
      users.keys.include?('cardinal').should == true
      users['crimson'].should == '2012-05-02 12:02:44 -0700'      
    end
  
  end

  describe "terms of acceptance for a new item" do
    
    subject { Hydrus::Collection.find('druid:oo000oo0003') }
    
    it "should indicate that a new item in a collection requires terms acceptance, if the user has already accepted another item in this collection but it was more than 1 year ago" do
      user='cardinal'
      subject.users_accepted_terms_of_deposit.keys.include?(user).should == true
      subject.users_accepted_terms_of_deposit[user] = (Time.now - 2.years).to_s # make the acceptance 2 years ago
      ni=Hydrus::Item.create(subject.pid,user)
      ni.requires_terms_acceptance(user,subject).should == true      
      ni.accepted_terms_of_deposit.should == "false"
      ni.terms_of_deposit_accepted?.should == false
    end

    it "should indicate that a new item in a collection does not require terms acceptance, if the user has already accepted another item in this collection less than 1 year ago" do
      user='crimson'
      subject.users_accepted_terms_of_deposit.keys.include?(user).should == true
      subject.users_accepted_terms_of_deposit[user] = (Time.now - 1.month).to_s # make the acceptance 1 month ago
      ni=Hydrus::Item.create(subject.pid,user)
      ni.requires_terms_acceptance(user,subject).should == false     
      ni.accepted_terms_of_deposit.should == "true" 
      ni.terms_of_deposit_accepted?.should == true
    end

    it "should indicate that a new item in a collection requires terms acceptance, when the user has not already accepted another item in this collection" do
      user='archivist1'
      ni=Hydrus::Item.create(subject.pid,user)
      ni.requires_terms_acceptance(user,subject).should == true 
      ni.accepted_terms_of_deposit.should == "false"
      ni.terms_of_deposit_accepted?.should == false
    end
  
    it "should accept the terms for an item, updating the appropriate hydrusProperties metadata in item and collection" do
      user='archivist1'
      ni=Hydrus::Item.create(subject.pid,user)
      ni.requires_terms_acceptance(user,subject).should == true      
      ni.accepted_terms_of_deposit.should == "false"
      subject.users_accepted_terms_of_deposit.keys.include?(user).should == false      
      ni.accept_terms_of_deposit(user)
      ni.accepted_terms_of_deposit.should == "true"
      ni.terms_of_deposit_accepted?.should == true
      coll=Hydrus::Collection.find('druid:oo000oo0003') 
      coll.users_accepted_terms_of_deposit.keys.include?(user).should == true      
      coll.users_accepted_terms_of_deposit[user].nil?.should == false   
    end
         
  end
end
