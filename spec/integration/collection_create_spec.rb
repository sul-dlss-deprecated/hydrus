require 'spec_helper'

describe("Collection create", :type => :request, :integration => true) do

  before(:all) do
    @notice = "Your changes have been saved."
    @edit_path_regex = Regexp.new('/collections/(druid:\w{11})/edit')
    # Need to mint an actual druid in order to pass validation.
    @prev_mint_ids = Dor::Config.configure.suri.mint_ids
    Dor::Config.configure.suri.mint_ids = true
  end

  after(:all) do
    # Restore mint_ids setting.
    Dor::Config.configure.suri.mint_ids = @prev_mint_ids
  end

  it "should be able to create a new Collection, with APO and related info" do
    ni = hash2struct(
      :title    => 'title_foo',
      :abstract => 'abstract_foo',
      :contact  => 'ozzy@hell.com',
    )
    # Login, go to new Collection page, and store the druid of the new Collection.
    login_as_archivist1
    visit new_hydrus_collection_path()
    current_path.should =~ @edit_path_regex
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in "hydrus_collection_title",    :with => ni.title
    fill_in "hydrus_collection_abstract", :with => ni.abstract
    fill_in "hydrus_collection_contact",  :with => ni.contact
    click_button "Save"
    page.should have_content(@notice)
    # Get Collection from fedora and confirm that our edits were persisted.
    coll = Hydrus::Collection.find(druid)
    coll.title.should    == ni.title
    coll.abstract.should == ni.abstract
    coll.contact.should  == ni.contact
    coll.should be_instance_of Hydrus::Collection
    # Get the APO of the Collection.
    apo = coll.apo
    apo.should be_instance_of Hydrus::AdminPolicyObject
    # Check workflow of Collection.
    wf_nodes = coll.workflows.find_by_terms(:workflow)
    wf_nodes.size.should == 1
    wf_nodes.first[:id].should == Dor::Config.hydrus.workflow_steps.keys.first.to_s
    # Check identityMetadata of Collection.
    coll.identityMetadata.tag.should include("Hydrus : collection", "Project : Hydrus")
    coll.identityMetadata.objectType.should include('collection', 'set')
    # Check person roles of the roleMetadata in APO and Collection.
    coll.apo_person_roles.should == { "collection-manager"   => { "archivist1" => true } }
    # apo.person_roles.should == { "collection-depositor" => { "archivist1" => true } }
    # Check APO.descMetadata.
    apo.title.should == Dor::Config.hydrus.initial_apo_title
    # Delete objects.
    coll.delete
    apo.delete
  end

end
