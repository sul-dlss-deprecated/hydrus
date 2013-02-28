require 'spec_helper'

describe("Collection create", :type => :request, :integration => true) do

  before(:each) do
    @alert           = 'div.alert'
    @notice_save     = "Your changes have been saved"
    @notice_open     = "Collection opened"
    @notice_close    = "Collection closed"
    @edit_path_regex = Regexp.new('/collections/(druid:\w{11})/edit')
    @prev_mint_ids   = config_mint_ids()
  end

  after(:each) do
    config_mint_ids(@prev_mint_ids)
  end

  it "should not be able to visit new collection URL if user lacks authority to create collections" do
    login_as('archivist99')
    visit new_hydrus_collection_path
    current_path.should == root_path
    find(@alert).should have_content("You do not have sufficient privileges")
  end

  it "should be able to create a new Collection, with APO, and with expected datastreams" do
    ni = hash2struct(
      :title    => 'title_foo',
      :abstract => 'abstract_foo',
      :contact  => 'ozzy@hell.com',
    )
    # Login, go to new Collection page, and store the druid of the new Collection.
    login_as('archivist1')
    visit new_hydrus_collection_path()
    current_path.should =~ @edit_path_regex
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in "hydrus_collection_title",    :with => ni.title
    fill_in "hydrus_collection_abstract", :with => ni.abstract
    fill_in "hydrus_collection_contact",  :with => ni.contact
    click_button "Save"
    find(@alert).should have_content(@notice_save)
    # Get Collection from fedora and confirm that our edits were persisted.
    coll = Hydrus::Collection.find(druid)
    coll.title.should    == ni.title
    coll.abstract.should == ni.abstract
    coll.contact.should  == ni.contact
    coll.should be_instance_of Hydrus::Collection
    coll.create_date.should_not be_blank
    coll.item_type.should == 'collection'
    # Get the APO of the Collection.
    apo = coll.apo
    apo.should be_instance_of Hydrus::AdminPolicyObject
    apo.defaultObjectRights.ng_xml.should be_equivalent_to coll.rightsMetadata.ng_xml # collection rights metadata should be equal to apo default object rights
    # Check workflow of Collection.
    wf_nodes = coll.workflows.find_by_terms(:workflow)
    wf_nodes.size.should == 1
    wf_nodes.first[:id].should == Dor::Config.hydrus.app_workflow.to_s
    # Check identityMetadata of Collection.
    coll.identityMetadata.tag.should include("Project : Hydrus")
    coll.identityMetadata.objectType.should include('collection', 'set')
    # Check person roles of the roleMetadata in APO
    coll.apo_person_roles.should == {
      "hydrus-collection-manager"   => Set.new([ "archivist1" ]),
      "hydrus-collection-depositor" => Set.new([ "archivist1" ]),
    }
    coll.collection_depositor.should == 'archivist1'
    # Check APO.descMetadata.
    apo.title.should == "APO for #{ni.title}"
    apo.label.should == "APO for #{ni.title}"
    # Check events.
    exp = [
      /\ACollection created/,
      /\ACollection modified/,
    ]
    es = coll.get_hydrus_events
    es.size.should == exp.size
    es[0...exp.size].zip(exp).each { |e, exp|
      e.text.should =~ exp
      e.who.should == 'archivist1'
      e.type.should == 'hydrus'
    }
  end

  it "should be able to create a new Collection, publish, close, etc" do
    ni = hash2struct(
      :title    => 'title_foo',
      :abstract => 'abstract_foo',
      :contact  => 'ozzy@hell.com',
    )
    open_button    = "Open Collection"
    close_button   = "Close Collection"
    # Login, go to new Collection page, and store the druid of the new Collection.
    login_as('archivist1')
    visit new_hydrus_collection_path()
    current_path.should =~ @edit_path_regex
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in "hydrus_collection_title", :with => ni.title
    choose "hydrus_collection_requires_human_approval_yes"
    click_button "Save"
    find(@alert).should have_content(@notice_save)
    # The view page should display some validation error messages, and should not
    # offer the Open Collection button.
    div_cs = find("div.collection-actions")
    div_cs.should_not have_button(open_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.object_status.should == 'draft'
    coll.is_openable.should == false
    coll.is_published.should == false
    coll.is_destroyable.should == true
    coll.submitted_for_publish_time.should be_blank
    coll.valid?.should == true  # Because unpublished, so validation is limited.
    coll.is_open.should == false
    # Go back to edit page and fill in required elements.
    should_visit_edit_page(coll)
    fill_in "hydrus_collection_abstract", :with => ni.abstract
    fill_in "hydrus_collection_contact",  :with => ni.contact
    click_button "Save"
    find(@alert).should have_content(@notice_save)
    # The view page should now offer the Open Collection button.
    page.should have_button(open_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.object_status.should == 'draft'
    coll.is_openable.should == true
    coll.is_published.should == false
    coll.is_destroyable.should == true
    coll.valid?.should == true
    coll.is_open.should == false
    # Open the Collection.
    click_button(open_button)
    find(@alert).should have_content(@notice_open)
    # The view page should now offer the Close Collection button.
    page.should have_button(close_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.object_status.should == 'published_open'
    coll.is_openable.should == false
    coll.is_published.should == true
    coll.is_destroyable.should == false
    coll.submitted_for_publish_time.should_not be_blank
    coll.valid?.should == true
    coll.is_open.should == true
    # The workflow steps of both the collection and apo should be completed.
    Dor::Config.hydrus.app_workflow_steps.each do |step|
      coll.workflows.workflow_step_is_done(step).should == true
      apo.workflows.workflow_step_is_done(step).should == true
    end
    # Close the Collection.
    click_button(close_button)
    find(@alert).should have_content(@notice_close)
    # The view page should now offer the Open Collection button.
    page.should have_button(open_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.object_status.should == 'published_closed'
    coll.is_openable.should == true
    coll.is_published.should == true
    coll.is_destroyable.should == false
    coll.valid?.should == true
    coll.is_open.should == false
    # Return to edit page, and try to save Collection with an empty title.
    click_link "Edit Collection"
    fill_in "hydrus_collection_title", :with => ''
    click_button "Save"
    page.should_not have_content(@notice_save)
    find('div.alert').should have_content('Title cannot be blank')
    # Fill in the title and save.
    fill_in "hydrus_collection_title", :with => ni.title
    click_button "Save"
    find(@alert).should have_content(@notice_save)
    # Open the Collection.
    click_button(open_button)
    find(@alert).should have_content(@notice_open)
    # The view page should now offer the Close Collection button.
    page.should have_button(close_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    coll.object_status.should == 'published_open'
    coll.is_openable.should == false
    coll.is_published.should == true
    coll.is_destroyable.should == false
    coll.valid?.should == true
    coll.is_open.should == true
    # Check events.
    exp = [
      /\ACollection created/,
      /\ACollection modified/,
      /\ACollection modified/,
      /\ACollection opened/,
      /\ACollection closed/,
      /\ACollection opened/,
    ]
    es = coll.get_hydrus_events
    es[0...exp.size].zip(exp).each { |e, exp| e.text.should =~ exp  }
  end

  describe "delete()" do

    it "should raise error if object is not destroyable" do
      hc = Hydrus::Collection.find('druid:oo000oo0004')
      hc.is_destroyable.should == false
      expect { hc.delete }.to raise_error(RuntimeError)
    end

    it "should fully delete collection and APO: from fedora, solr, workflows" do
      # Setup.
      hyc = Hydrus::Collection
      hya = Hydrus::AdminPolicyObject
      afe = ActiveFedora::ObjectNotFoundError
      wfs = Dor::WorkflowService
      hwf = Dor::Config.hydrus.app_workflow.to_s
      # Create a new collection.
      hc   = create_new_collection()
      apo  = hc.apo
      apid = hc.apo.pid
      cpid = hc.pid
      # Confirm existence of objects:
      #   - in Fedora
      apo.class.should == hya
      hc.class.should  == hyc
      #   - in SOLR
      hyc.all_hydrus_objects(:models => [hya], :pids_only => true).should include(apid)
      hyc.all_hydrus_objects(:models => [hyc], :pids_only => true).should include(cpid)
      #   - in workflows
      wfs.get_workflows(apid).should == [hwf]
      wfs.get_workflows(cpid).should == [hwf]
      # Delete the collection and its APO.
      hc.is_destroyable.should == true
      click_link "Discard this collection"
      click_button "Discard"
      hc = nil
      # Confirm that objects were deleted:
      #   - from Fedora
      expect { hya.find(apid) }.to raise_error(afe)
      expect { hyc.find(cpid) }.to raise_error(afe)
      #   - from SOLR
      hyc.all_hydrus_objects(:models => [hya], :pids_only => true).should_not include(apid)
      hyc.all_hydrus_objects(:models => [hyc], :pids_only => true).should_not include(cpid)
      #   - from workflows
      wfs.get_workflows(apid).should == []
      wfs.get_workflows(cpid).should == []
    end

  end

end
