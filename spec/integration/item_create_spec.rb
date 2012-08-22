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

  it "should be able to create a new Item, with expected datastreams" do
    # Login, go to new Item page, and store the druid of the new Item.
    login_as_archivist1
    visit new_hydrus_item_path(:collection => @hc_druid)
    current_path.should =~ @edit_path_regex
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
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
    item.person_roles.should == { "hydrus-item-depositor" => ["archivist1"] }
    # Check events.
    es = item.get_hydrus_events
    es.size.should == 1
    e = es.first
    e.text.should =~ /\AItem created/
    e.who.should == 'archivist1'
    e.type.should == 'hydrus'
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
    )
    publish_button    = "Submit for Approval"
    approve_button    = "Approve"
    disapprove_button = "Disapprove"
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
    fill_in "Title of item", :with => ni.title
    click_button "Save"
    page.should have_content(@notice)
    # The view page should display some validation error messages, and should not
    # offer the Publish button.
    div_cs = find("div.collection-actions")
    div_cs.should_not have_button(publish_button)
    err_msgs = div_cs.all('li').map { |e| e.text }.join("\n")
    exp = [
      /^Abstract/,
      /^Contact/,
      /^Files/,
      /^Terms/,
    ]
    exp.each { |e| err_msgs.should =~ e }
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    item.is_publishable.should == false
    item.is_published.should == false
    item.is_approved.should == false
    item.is_disapproved.should == false
    item.is_destroyable.should == true
    item.valid?.should == true  # Because unpublished, so validation is limited.
    # Go back to edit page and fill in required elements.
    should_visit_edit_page(item)
    fill_in "hydrus_item_abstract", :with => ni.abstract
    fill_in "hydrus_item_contact",  :with => ni.contact
    check "hydrus_item[accepted_terms_of_deposit]"
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
    click_link "Switch to edit view"
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
      /\AItem published/,
      /\AItem disapproved/,
      /\AItem approved/,
    ]
    es = item.get_hydrus_events
    es[0...exp.size].zip(exp).each { |e, exp| e.text.should =~ exp  }
  end

end
