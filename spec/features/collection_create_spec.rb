require 'spec_helper'

RSpec.describe('Collection create', type: :request, integration: true) do
  let(:archivist1) { create :archivist1 }
  let(:archivist99) { create :archivist99 }
  let(:wfs) { Dor::Config.workflow.client }

  before do
    @alert           = 'div.alert'
    @notice_save     = 'Your changes have been saved'
    @notice_open     = 'Collection opened'
    @notice_close    = 'Collection closed'
    @edit_path_regex = Regexp.new('/collections/(druid:\w{11})/edit')
    @prev_mint_ids   = config_mint_ids()
  end

  after(:each) do
    config_mint_ids(@prev_mint_ids)
  end

  it 'should not be able to visit new collection URL if user lacks authority to create collections' do
    sign_in(archivist99)
    visit new_hydrus_collection_path
    expect(current_path).to eq(root_path)
    expect(find(@alert)).to have_content('You do not have sufficient privileges')
  end

  it 'should be able to create a new Collection, with APO, and with expected datastreams' do
    ni = OpenStruct.new(
      title: 'title_foo',
      abstract: 'abstract_foo',
      contact: 'ozzy@hell.com',
    )
    # Login, go to new Collection page, and store the druid of the new Collection.
    sign_in(archivist1)
    visit new_hydrus_collection_path()
    expect(current_path).to match(@edit_path_regex)
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in 'hydrus_collection_title',    with: ni.title
    fill_in 'hydrus_collection_abstract', with: ni.abstract
    fill_in 'hydrus_collection_contact',  with: ni.contact
    click_button 'save_nojs'
    expect(find(@alert)).to have_content(@notice_save)
    # Get Collection from fedora and confirm that our edits were persisted.
    coll = Hydrus::Collection.find(druid)
    expect(coll.title).to    eq(ni.title)
    expect(coll.abstract).to eq(ni.abstract)
    expect(coll.contact).to  eq(ni.contact)
    expect(coll).to be_instance_of Hydrus::Collection
    expect(coll.create_date).not_to be_blank
    expect(coll.item_type).to eq('collection')
    # Get the APO of the Collection.
    apo = coll.apo
    expect(apo).to be_instance_of Hydrus::AdminPolicyObject
    expect(apo.defaultObjectRights.ng_xml).to be_equivalent_to coll.rightsMetadata.ng_xml # collection rights metadata should be equal to apo default object rights
    # Check workflow of Collection.
    wf_xml = Dor::Config.workflow.client.all_workflows_xml(druid)
    wf_nodes = Dor::Workflow::Response::Workflows.new(xml: wf_xml).workflows
    expect(wf_nodes.size).to eq(1)
    expect(wf_nodes.first.workflow_name).to eq(Settings.hydrus.app_workflow.to_s)
    # Check identityMetadata of Collection.
    expect(coll.identityMetadata.tag.to_a).to include('Project : Hydrus')
    expect(coll.identityMetadata.objectType.to_a).to include('collection', 'set')
    # Check the typeOfResource of the collection
    expect(coll.descMetadata.ng_xml.search('//mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').first['collection']).to eq('yes')
    expect(coll.descMetadata.ng_xml.search('//mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').first.text).to eq('mixed material')
    # Check person roles of the roleMetadata in APO
    expect(coll.apo_person_roles).to eq({
                                          'hydrus-collection-manager' => Set.new(['archivist1']),
                                          'hydrus-collection-depositor' => Set.new(['archivist1']),
                                        })
    expect(coll.collection_depositor).to eq('archivist1')
    # Check APO.descMetadata.
    expect(apo.title).to eq("APO for #{ni.title}")
    expect(apo.label).to eq("APO for #{ni.title}")
    # Check events.
    es = coll.get_hydrus_events
    expect(es.size).to eq(2)

    expect(es.first.text).to match /\ACollection created/
    expect(es.first.who).to eq 'archivist1'
    expect(es.first.type).to eq 'hydrus'
    expect(es.last.text).to match /\ACollection modified/
    expect(es.last.who).to eq 'archivist1'
    expect(es.last.type).to eq 'hydrus'
  end

  it 'should be able to create a new Collection, publish, close, etc' do
    ni = OpenStruct.new(
      title: 'title_foo',
      abstract: 'abstract_foo',
      contact: 'ozzy@hell.com',
    )
    open_button    = 'Open Collection'
    close_button   = 'Close Collection'
    # Login, go to new Collection page, and store the druid of the new Collection.
    sign_in(archivist1)
    visit new_hydrus_collection_path()
    expect(current_path).to match(@edit_path_regex)
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in 'hydrus_collection_title', with: ni.title
    choose 'hydrus_collection_requires_human_approval_yes'
    click_button 'save_nojs'
    expect(find(@alert)).to have_content(@notice_save)
    # The view page should display some validation error messages, and should not
    # offer the Open Collection button.
    div_cs = find('div.collection-actions')
    expect(div_cs).not_to have_button(open_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    expect(coll.object_status).to eq('draft')
    expect(coll.is_openable).to eq(false)
    expect(coll.is_published).to eq(false)
    expect(coll.is_destroyable).to eq(true)
    expect(coll.submitted_for_publish_time).to be_blank
    expect(coll.valid?).to eq(true) # Because unpublished, so validation is limited.
    expect(coll.is_open).to eq(false)
    # Go back to edit page and fill in required elements.
    should_visit_edit_page(coll)
    fill_in 'hydrus_collection_abstract', with: ni.abstract
    fill_in 'hydrus_collection_contact',  with: ni.contact
    click_button 'save_nojs'
    expect(find(@alert)).to have_content(@notice_save)
    # The view page should now offer the Open Collection button.
    expect(page).to have_button(open_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    expect(coll.object_status).to eq('draft')
    expect(coll.is_openable).to eq(true)
    expect(coll.is_published).to eq(false)
    expect(coll.is_destroyable).to eq(true)
    expect(coll.valid?).to eq(true)
    expect(coll.is_open).to eq(false)
    # Open the Collection.
    click_button(open_button)
    expect(find(@alert)).to have_content(@notice_open)
    # The view page should now offer the Close Collection button.
    expect(page).to have_button(close_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    expect(coll.object_status).to eq('published_open')
    expect(coll.is_openable).to eq(false)
    expect(coll.is_published).to eq(true)
    expect(coll.is_destroyable).to eq(false)
    expect(coll.submitted_for_publish_time).not_to be_blank
    expect(coll.valid?).to eq(true)
    expect(coll.is_open).to eq(true)
    # The workflow steps of both the collection and apo should be completed.
    %w(start-deposit submit approve start-assembly).each do |step|
      expect(
        wfs.workflow_status(druid: coll.pid, workflow: Settings.hydrus.app_workflow, process: step)
      ).to eq('completed')
      expect(
        wfs.workflow_status(druid: apo.pid, workflow: Settings.hydrus.app_workflow, process: step)
      ).to eq('completed')
    end
    # Close the Collection.
    click_button(close_button)
    expect(find(@alert)).to have_content(@notice_close)
    # The view page should now offer the Open Collection button.
    expect(page).to have_button(open_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    expect(coll.object_status).to eq('published_closed')
    expect(coll.is_openable).to eq(true)
    expect(coll.is_published).to eq(true)
    expect(coll.is_destroyable).to eq(false)
    expect(coll.valid?).to eq(true)
    expect(coll.is_open).to eq(false)
    # Return to edit page, and try to save Collection with an empty title.
    click_link 'Edit Collection'
    fill_in 'hydrus_collection_title', with: ''
    click_button 'save_nojs'
    expect(page).not_to have_content(@notice_save)
    expect(find('div.alert')).to have_content('Title cannot be blank')
    # Fill in the title and save.
    fill_in 'hydrus_collection_title', with: ni.title
    click_button 'save_nojs'
    expect(find(@alert)).to have_content(@notice_save)
    # Open the Collection.
    click_button(open_button)
    expect(find(@alert)).to have_content(@notice_open)
    # The view page should now offer the Close Collection button.
    expect(page).to have_button(close_button)
    # Get the Collection and APO objects from fedora.
    coll = Hydrus::Collection.find(druid)
    apo = coll.apo
    # Check various Collection attributes and methods.
    expect(coll.object_status).to eq('published_open')
    expect(coll.is_openable).to eq(false)
    expect(coll.is_published).to eq(true)
    expect(coll.is_destroyable).to eq(false)
    expect(coll.valid?).to eq(true)
    expect(coll.is_open).to eq(true)

    # Check events.
    es = coll.get_hydrus_events

    expect(es.map(&:text)).to match_array [
      /\ACollection created/,
      /\ACollection modified/,
      /\ACollection modified/,
      /\ACollection opened/,
      /\ACollection closed/,
      /\ACollection opened/,
    ]
  end

  describe 'delete()' do
    it 'should raise error if object is not destroyable' do
      hc = Hydrus::Collection.find('druid:bb000bb0004')
      expect(hc.is_destroyable).to eq(false)
      expect { hc.delete }.to raise_error(RuntimeError)
    end

    it 'should fully delete collection and APO: from fedora, solr, workflows' do
      sign_in(archivist1)
      # Setup.
      hyc = Hydrus::Collection
      hya = Hydrus::AdminPolicyObject
      afe = ActiveFedora::ObjectNotFoundError
      hwf = Settings.hydrus.app_workflow.to_s
      # Create a new collection.
      hc   = create_new_collection()
      apo  = hc.apo
      apid = hc.apo.pid
      cpid = hc.pid
      # Confirm existence of objects:
      #   - in Fedora
      expect(apo.class).to eq(hya)
      expect(hc.class).to  eq(hyc)
      #   - in SOLR
      expect(hyc.all_hydrus_objects(models: [hya], pids_only: true)).to include(apid)
      expect(hyc.all_hydrus_objects(models: [hyc], pids_only: true)).to include(cpid)
      #   - in workflows
      expect(wfs.workflows(apid)).to eq([hwf])
      expect(wfs.workflows(cpid)).to eq([hwf])
      # Delete the collection and its APO.
      expect(hc.is_destroyable).to eq(true)
      click_link 'Discard this collection'
      click_button 'Discard'
      hc = nil
      # Confirm that objects were deleted:
      #   - from Fedora
      expect { hya.find(apid) }.to raise_error(afe)
      expect { hyc.find(cpid) }.to raise_error(afe)
      #   - from SOLR
      expect(hyc.all_hydrus_objects(models: [hya], pids_only: true)).not_to include(apid)
      expect(hyc.all_hydrus_objects(models: [hyc], pids_only: true)).not_to include(cpid)
      #   - from workflows
      expect(wfs.workflows(apid)).to eq([])
      expect(wfs.workflows(cpid)).to eq([])
    end
  end
end
