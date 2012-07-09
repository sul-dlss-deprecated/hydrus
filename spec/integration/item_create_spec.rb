require 'spec_helper'

describe("Item create", :type => :request, :integration => true) do

  before :all do
    @notice = "Your changes have been saved."
  end

  it "should be able to create a new Item" do
    # Need to mint an actual druid in order to pass validation.
    prev_mint_ids = Dor::Config.configure.suri.mint_ids
    Dor::Config.configure.suri.mint_ids = true
    # Login, go to new Item page, and save the druid.
    login_as_archivist1
    visit new_hydrus_item_path(:collection => 'druid:oo000oo0003')
    path_regex = Regexp.new('/items/(druid:\w{11})/edit')
    current_path.should =~ path_regex
    druid = path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in "Title of item", :with => 'title_foo'
    fill_in "hydrus_item_person_0", :with => 'person_foo'
    fill_in "Abstract", :with => 'abstract_foo'
    click_button "Save"
    page.should have_content(@notice)
    # Get Item out of fedora and confirm that our edits made it.
    item = Hydrus::Item.find(druid)
    item.title.first.should == 'title_foo'
    item.person.first.should == 'person_foo'
    item.abstract.first.should == 'abstract_foo'
    item.should be_instance_of Hydrus::Item
    # Delete object and restore mint_ids setting.
    item.delete
    Dor::Config.configure.suri.mint_ids = prev_mint_ids
  end

  # Another test
  #   - don't fill in required items

  # Another test
  #   visit via click button from Collection screen

end
