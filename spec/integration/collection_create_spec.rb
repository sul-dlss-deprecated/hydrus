require 'spec_helper'

describe("Collection create", :type => :request, :integration => true) do

  before(:each) do
    @notice = "Your changes have been saved"
    @edit_path_regex = Regexp.new('/collections/(druid:\w{11})/edit')
    @prev_mint_ids = config_mint_ids()
  end

  after(:each) do
    config_mint_ids(@prev_mint_ids)
  end

  it "should be able to create a new Collection, with APO, and with expected datastreams" do
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
    coll.person_roles.should     == { "collection-depositor" => { "archivist1" => true } }
    # Check APO.descMetadata.
    apo.title.should == Dor::Config.hydrus.initial_apo_title
    # Check events.
    es = coll.get_hydrus_events
    es.size.should == 1
    e = es.first
    e.text.should =~ /\ACollection created/
    e.who.should == 'archivist1'
    e.type.should == 'hydrus'
  end

  it "should be able to create a new Collection, publish, close, etc" do
    ni = hash2struct(
      :title    => 'title_foo',
      :abstract => 'abstract_foo',
      :contact  => 'ozzy@hell.com',
    )
    open_button  = "Open Collection"
    close_button = "Close Collection"
    # Login, go to new Collection page, and store the druid of the new Collection.
    login_as_archivist1
    visit new_hydrus_collection_path()
    current_path.should =~ @edit_path_regex
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in "hydrus_collection_title", :with => ni.title
    click_button "Save"
    page.should have_content(@notice)
    # The view page should display some validation error messages, and should not
    # offer the Open Collection button.
    div_cs = find("div.collection-actions")
    div_cs.should_not have_button(open_button)
    err_msgs = div_cs.all('li').map { |e| e.text }.join("\n")
    exp = [
      /^Abstract/,
      /^Contact/,
      /^Embargo must/,
      /^License must/,
      /^Embargo option/,
      /^License option/,
    ]
    exp.each { |e| err_msgs.should =~ e }
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.is_publishable.should == false
    coll.is_published.should == false
    coll.is_approved.should == false
    coll.is_destroyable.should == true
    coll.valid?.should == true  # Because unpublished, so validation is limited.
    coll.is_open.should == false
    apo.is_open.should == false
    # Go back to edit page and fill in required elements.
    should_visit_edit_page(coll)
    fill_in "hydrus_collection_abstract", :with => ni.abstract
    fill_in "hydrus_collection_contact",  :with => ni.contact
    choose "hydrus_collection_embargo_option_none"
    choose "hydrus_collection_visibility_option_value_everyone"
    choose "hydrus_collection_license_option_none"
    click_button "Save"
    page.should have_content(@notice)
    # The view page should now offer the Open Collection button.
    div_cs = find("div.collection-actions")
    div_cs.should have_button(open_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.is_publishable.should == true
    coll.is_published.should == false
    coll.is_approved.should == false
    coll.is_destroyable.should == true
    coll.valid?.should == true
    coll.is_open.should == false
    apo.is_open.should == false
    # Open the Collection.
    click_button(open_button)
    page.should have_content(@notice)
    # The view page should now offer the Close Collection button.
    div_cs = find("div.collection-actions")
    div_cs.should have_button(close_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.is_publishable.should == true
    coll.is_published.should == true
    coll.is_approved.should == true     # human approval was not required
    coll.is_destroyable.should == false
    coll.valid?.should == true
    coll.is_open.should == true
    apo.is_open.should == true
    # Close the Collection.
    click_button(close_button)
    page.should have_content(@notice)
    # The view page should now offer the Open Collection button.
    div_cs = find("div.collection-actions")
    div_cs.should have_button(open_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.is_publishable.should == true
    coll.is_published.should == true
    coll.is_approved.should == true
    coll.is_destroyable.should == false
    coll.valid?.should == true
    coll.is_open.should == false
    apo.is_open.should == false
    # Return to edit page, and try to save Collection with an empty title.
    click_link "Switch to edit view"
    fill_in "hydrus_collection_title", :with => ''
    click_button "Save"
    page.should_not have_content(@notice)
    find('div.alert').should have_content('Title cannot be blank')
    # Check events.
    exp = [
      /\ACollection created/,
      /\ACollection opened/,
      /\AApproved/,
      /\ACollection closed/,
    ]
    es = coll.get_hydrus_events
    es[0...exp.size].zip(exp).each { |e, exp| e.text.should =~ exp  }
  end

end
