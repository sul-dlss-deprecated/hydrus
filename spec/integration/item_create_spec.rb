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
    item.person_roles.should == { "item-depositor" => { "archivist1" => true } }
  end

  it "should be able to access create-new-Item screen via the Collection view page" do
    login_as_archivist1
    collection = Hydrus::Collection.find(@hc_druid)
    visit polymorphic_path(collection)
    click_link('item')
    current_path.should =~ @edit_path_regex
  end

end
