require 'spec_helper'

describe('Item create', type: :request, integration: true) do
  let(:archivist1) { create :archivist1 }
  let(:archivist6) { create :archivist6 }
  before(:all) do
    @div_alert   = '#flash-notices div.alert'
    @span_status = 'span#status-label'
    @div_actions = 'div.panel-default'
    @notices = {
      save: 'Your changes have been saved.',
      publish_directly: 'Item published: v',
      submit_for_approval: 'Item submitted for approval.',
      approve: 'Item approved and published: v',
      disapprove: 'Item returned.',
      resubmit: 'Item resubmitted for approval.',
    }
    @status_msgs = {
      draft: 'Draft',
      awaiting_approval: 'Waiting for approval',
      returned: 'Item returned',
      published: 'Published',
    }
    @buttons = {
      add: 'Add',
      save: 'save_nojs',
      add_contributor: 'Add Contributor',
      submit_for_approval: 'Submit for Approval',
      resubmit: 'Resubmit for Approval',
      disapprove: 'Return',
      approve: 'Approve and Publish',
      publish_directly: 'Publish',
    }
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

  context 'depositing items into collections' do
    it 'should have a non-js select list for depositing items into collections' do
      sign_in(archivist1)
      visit hydrus_collection_path(id: @hc_druid)
      select 'data set', from: 'type'
      click_button('Add new item')
      expect(current_path).not_to eq(hydrus_collection_path(id: @hc_druid))
      expect(current_path).to match(@edit_path_regex)
    end

    it 'should be able to access create-new-Item screen via the Collection view page' do
      Capybara.ignore_hidden_elements = false
      sign_in(archivist1)
      collection = Hydrus::Collection.find(@hc_druid)
      visit polymorphic_path(collection)
      click_link 'data set'
      expect(current_path).to match(@edit_path_regex)
      Capybara.ignore_hidden_elements = true
    end
  end

  it 'should be able to create a new default Item type, with expected datastreams' do
    # Login, go to new Item page, and store the druid of the new Item.
    sign_in(archivist1)
    visit new_hydrus_item_path(collection: @hc_druid)
    expect(current_path).to match(@edit_path_regex)
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in 'Title of item', with: 'title_foo'
    fill_in 'hydrus_item_contributors_0_name', with: 'contributor_foo'
    fill_in 'Abstract', with: 'abstract_foo'
    click_button(@buttons[:save])
    expect(find(@div_alert)).to have_content(@notices[:save])
    # Get Item out of fedora and confirm that our edits were persisted.
    item = Hydrus::Item.find(druid)
    expect(item.title).to eq('title_foo')
    expect(item.contributors.first.name).to eq('contributor_foo')
    expect(item.abstract).to eq('abstract_foo')
    expect(item).to be_instance_of Hydrus::Item
    expect(item.create_date).not_to be_blank
    expect(item.item_type).to eq('dataset')
    expect(item.descMetadata.typeOfResource).to eq(['software, multimedia'])
    # Check workflow of Item.
    wf_nodes = item.workflows.find_by_terms(:workflow)
    expect(wf_nodes.size).to eq(1)
    expect(wf_nodes.first[:id]).to eq(Dor::Config.hydrus.app_workflow.to_s)
    # Check identityMetadata of Item.
    expect(item.identityMetadata.tag.to_a).to include('Project : Hydrus')
    # Check roles of the Item.
    expect(item.person_roles).to eq({ 'hydrus-item-depositor' => Set.new(['archivist1']) })

    # Check events.
    es = item.get_hydrus_events
    expect(es.size).to eq(2)
    expect(es.first.text).to match(/\AItem created/)
    expect(es.first.who).to eq('archivist1')
    expect(es.first.type).to eq('hydrus')

    expect(es.last.text).to match(/\AItem modified/)
    expect(es.last.who).to eq('archivist1')
    expect(es.last.type).to eq('hydrus')
  end

  it 'should not be able to publish an item if there are no contributors' do
    # Login, go to new Item page, and store the druid of the new Item.
    sign_in(archivist1)
    visit new_hydrus_item_path(collection: @hc_druid, type: 'article')
    expect(current_path).to match(@edit_path_regex)
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form with all required fields (except contributor) and save.
    fill_in 'Title of item', with: 'title_article'
    fill_in 'hydrus_item_contact', with: 'bogus_email@test.com'
    fill_in 'Abstract', with: 'abstract_article'
    fill_in 'Keywords', with: 'keyword'
    fill_in 'hydrus_item_dates_date_created', with: '2017'
    check 'terms_of_deposit_checkbox'
    check 'release_settings'
    f = Hydrus::ObjectFile.new
    f.pid = druid
    f.file = Tempfile.new('mock_HydrusObjectFile_')
    f.save
    click_button(@buttons[:save])

    # confirm validation message is shown and publish button is not available
    expect(find(@div_alert)).to have_content(@notices[:save])
    expect(find(@div_alert)).to have_content('Contributors must be entered')
    expect(page).to_not have_button('Publish')

    # add in a contributor and confirm validation message goes away and publish button appears
    visit edit_hydrus_item_path(druid)
    fill_in 'hydrus_item_contributors_0_name', with: 'Some, person' # nonblank contributor
    click_button(@buttons[:save])
    expect(find(@div_alert)).to_not have_content('Contributors must be entered')
    expect(page).to have_button('Publish')
  end

  it 'should be able to create a new article type Item, with expected datastreams' do
    # Login, go to new Item page, and store the druid of the new Item.
    sign_in(archivist1)
    visit new_hydrus_item_path(collection: @hc_druid, type: 'article')
    expect(current_path).to match(@edit_path_regex)
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in 'Title of item', with: 'title_article'
    fill_in 'hydrus_item_contributors_0_name', with: 'contributor_article'
    fill_in 'Abstract', with: 'abstract_article'
    click_button(@buttons[:save])
    expect(find(@div_alert)).to have_content(@notices[:save])
    # Get Item out of fedora and confirm that our edits were persisted.
    item = Hydrus::Item.find(druid)
    expect(item.title).to eq('title_article')
    expect(item.contributors.first.name).to eq('contributor_article')
    expect(item.abstract).to eq('abstract_article')
    expect(item).to be_instance_of Hydrus::Item
    expect(item.create_date).not_to be_blank
    expect(item.item_type).to eq('article')
    expect(item.descMetadata.typeOfResource).to eq(['text'])
    expect(item.descMetadata.genre).to eq(['article'])
  end

  it 'should be able to create a new class project Item, with expected datastreams' do
    # Login, go to new Item page, and store the druid of the new Item.
    sign_in(archivist1)
    visit new_hydrus_item_path(collection: @hc_druid, type: 'class project')
    expect(current_path).to match(@edit_path_regex)
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in 'Title of item', with: 'title_article'
    fill_in 'hydrus_item_contributors_0_name', with: 'contributor_article'
    fill_in 'Abstract', with: 'abstract_article'
    click_button(@buttons[:save])

    expect(find(@div_alert)).to have_content(@notices[:save])
    # Get Item out of fedora and confirm that our edits were persisted.
    item = Hydrus::Item.find(druid)
    expect(item.title).to eq('title_article')
    expect(item.contributors.first.name).to eq('contributor_article')
    expect(item.abstract).to eq('abstract_article')
    expect(item).to be_instance_of Hydrus::Item
    expect(item.create_date).not_to be_blank
    expect(item.item_type).to eq('class project')
    expect(item.descMetadata.typeOfResource).to eq(['text'])
    expect(item.descMetadata.genre).to eq(['student project report'])
  end

  it 'Requires approval: should be able to submit, disapprove, resubmit, approve, etc' do
    # Setup.
    ni = OpenStruct.new(
      title: 'title_foo',
      abstract: 'abstract_foo',
      contact: 'ozzy@hell.com',
      reason: 'Idiota',
      contributor: 'contributor_foo',
      keywords: 'aaa,bbb',
      date_created: '2011',
    )

    # Force Items to receive human approval.
    coll = Hydrus::Collection.find(@hc_druid)
    coll.requires_human_approval = 'yes'
    coll.save

    # Login as a item depositor for this collection, go to new Item page, and
    # store the druid of the new Item.
    sign_in(archivist6)
    visit new_hydrus_item_path(collection: @hc_druid)
    expect(page).to have_content('Welcome archivist6')
    expect(current_path).to match(@edit_path_regex)
    druid = @edit_path_regex.match(current_path)[1]

    # Fill in form and save.
    fill_in 'hydrus_item_contributors_0_name', with: ni.contributor
    fill_in 'Title of item', with: ni.title
    click_button(@buttons[:save])
    expect(find(@div_alert)).to have_content(@notices[:save])

    # The view page should display some validation error messages, and should
    # not offer the Submit for approval button.
    expect(find(@div_actions)).not_to have_button(@buttons[:submit_for_approval])
    expect(find(@span_status)).to have_content(@status_msgs[:draft])

    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('draft')
    item.is_draft == true
    expect(item.is_awaiting_approval).to eq(false)
    expect(item.is_publishable).to eq(false)
    expect(item.is_published).to eq(false)
    expect(item.is_returned).to eq(false)
    expect(item.is_destroyable).to eq(true)
    expect(item.submitted_for_publish_time).to be_blank
    expect(item.accepted_terms_of_deposit).to eq('false')
    expect(item.valid?).to eq(true) # Because unpublished, so validation is limited.

    # Go back to edit page and fill in required elements.
    should_visit_edit_page(item)
    check 'release_settings'
    fill_in 'hydrus_item_abstract', with: ni.abstract
    fill_in 'hydrus_item_contact',  with: ni.contact
    fill_in 'hydrus_item_keywords', with: ni.keywords
    fill_in 'hydrus_item_dates_date_created', with: ni.date_created
    f = Hydrus::ObjectFile.new
    f.pid = druid
    f.file = Tempfile.new('mock_HydrusObjectFile_')
    f.save
    click_button(@buttons[:save])
    expect(find(@div_alert)).to have_content(@notices[:save])

    # The view page should still not offer the Submit for approval button since
    # we haven't accepted the terms.
    expect(find(@div_actions)).not_to have_button(@buttons[:submit_for_approval])

    # Accept terms of deposit
    should_visit_edit_page(item)
    check 'terms_of_deposit_checkbox'
    click_button(@buttons[:save])

    # The view page should now offer the Submit for approval button (but no publish button) since we
    # have accepted the terms.
    visit hydrus_item_path(id: item.pid)
    expect(find(@div_actions)).to have_button(@buttons[:submit_for_approval])
    expect(find(@div_actions)).not_to have_button(@buttons[:publish_directly])

    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('draft')
    expect(item.is_draft).to eq(true)
    expect(item.is_awaiting_approval).to eq(false)
    expect(item.is_publishable_directly).to eq(false)
    expect(item.is_publishable).to eq(false)
    expect(item.is_submittable_for_approval).to eq(true)
    expect(item.submit_for_approval_time).to be_blank
    expect(item.is_published).to eq(false)
    expect(item.is_returned).to eq(false)
    expect(item.is_destroyable).to eq(true)
    expect(item.valid?).to eq(true)

    # Submit the Item for approval.
    click_button(@buttons[:submit_for_approval])
    expect(find(@div_alert)).to have_content(@notices[:submit_for_approval])

    # The view page should not offer the Submit for approval button or the publish button
    expect(find(@div_actions)).not_to have_button(@buttons[:submit_for_approval])
    expect(find(@div_actions)).not_to have_button(@buttons[:publish_directly])
    expect(find(@span_status)).to have_content(@status_msgs[:awaiting_approval])

    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('awaiting_approval')
    expect(item.is_publishable).to eq(true)
    expect(item.is_publishable_directly).to eq(false)
    expect(item.requires_human_approval).to eq('yes')
    expect(item.is_published).to eq(false)
    expect(item.is_returned).to eq(false)
    expect(item.is_destroyable).to eq(true)
    expect(item.submitted_for_publish_time).to be_blank
    expect(item.submit_for_approval_time).not_to be_blank
    expect(item.valid?).to eq(true)

    # Return to edit page, and try to save Item with an empty title.
    click_link 'Edit Draft'
    fill_in 'hydrus_item_title', with: ''
    click_button(@buttons[:save])
    expect(find(@div_alert)).not_to have_content(@notices[:save])
    expect(find(@div_alert)).to have_content('Title cannot be blank')

    # Fill in the title and save.
    fill_in 'hydrus_item_title', with: ni.title
    click_button(@buttons[:save])
    expect(find(@div_alert)).to have_content(@notices[:save])

    # now login as archivist 1 (collection manager) and Disapprove the Item.
    sign_in(archivist1)
    visit hydrus_item_path(id: item.pid)
    expect(page).to have_content('Welcome archivist1')
    fill_in 'hydrus_item_disapproval_reason', with: ni.reason
    e = expect { click_button(@buttons[:disapprove]) }
    e.to change { ActionMailer::Base.deliveries.count }.by(1)

    expect(find(@div_alert)).to have_content(@notices[:disapprove])

    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('returned')
    expect(item.is_publishable).to eq(false)
    expect(item.is_publishable_directly).to eq(false)
    expect(item.is_published).to eq(false)
    expect(item.is_returned).to eq(true)
    expect(item.is_destroyable).to eq(true)
    expect(item.valid?).to eq(true)
    expect(item.disapproval_reason).to eq(ni.reason)
    visit hydrus_item_path(id: item.pid)
    expect(find(@span_status)).to have_content(@status_msgs[:returned])

    # now login as archivist 6 (depositor) and resubmit the Item.
    sign_in(archivist6)
    visit hydrus_item_path(id: item.pid)
    expect(page).to have_content('Welcome archivist6')
    expect(page).to have_content(ni.reason)
    expect(find(@span_status)).to have_content(@status_msgs[:returned])
    click_button(@buttons[:resubmit])
    expect(find(@div_alert)).to have_content(@notices[:resubmit])

    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('awaiting_approval')
    expect(item.is_publishable).to eq(true)
    expect(item.is_publishable_directly).to eq(false)
    expect(item.is_published).to eq(false)
    expect(item.is_returned).to eq(false)
    expect(item.is_destroyable).to eq(true)
    expect(item.valid?).to eq(true)
    expect(item.disapproval_reason).to eq(nil)
    expect(find(@span_status)).to have_content(@status_msgs[:awaiting_approval])

    # Now login as archivist 1 and approve the item.
    sign_in(archivist1)
    visit hydrus_item_path(id: item.pid)
    click_button(@buttons[:approve])
    expect(find(@div_alert)).to have_content(@notices[:approve])

    # The view page should not offer the Publish, Approve, or Disapprove buttons.
    div_cs = find(@div_actions)
    expect(div_cs).not_to have_button(@buttons[:submit_for_approval])
    expect(div_cs).not_to have_button(@buttons[:approve])
    expect(div_cs).not_to have_button(@buttons[:disapprove])
    expect(find(@span_status)).to have_content(@status_msgs[:published])

    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('published')
    expect(item.is_publishable).to eq(false)
    expect(item.is_published).to eq(true)
    expect(item.is_returned).to eq(false)
    expect(item.is_destroyable).to eq(false)
    expect(item.valid?).to eq(true)
    expect(item.disapproval_reason).to eq(nil)
    expect(item.is_embargoed).to eq(false)
    expect(item.submitted_for_publish_time).not_to be_blank
    expect(item.visibility).to eq(['stanford'])
    ps = { visibility: 'stanford', license_code: 'cc-by', embargo_date: '' }
    check_emb_vis_lic(item, ps)

    # Check events.
    es = item.get_hydrus_events
    expect(es.map(&:text)).to match_array [
      /\AItem created/,
      /\AItem modified/,
      /\AItem modified/,
      /\ATerms of deposit accepted/,
      /\AItem submitted for approval/,
      /\AItem returned/,
      /\AItem resubmitted for approval/,
      /\AItem approved/,
      /\AItem published/,
    ]
  end

  it 'Does not require approval: should be able to publish directly, with world visible rights and a different license than collection' do
    ni = OpenStruct.new(
      title: 'title_foo',
      abstract: 'abstract_foo',
      contact: 'ozzy@hell.com',
      reason: 'Idiota',
      contributor: 'contributor_foo',
      keywords: 'aaa,bbb',
      date_created: '2011',
    )
    # Force Items to not receive human approval and have varied visiblity and licenses
    coll = Hydrus::Collection.find(@hc_druid)
    coll.requires_human_approval = 'no'
    coll.visibility_option_value = 'varies'
    coll.license = 'cc-by-sa'
    coll.license_option = 'varies'
    coll.save

    # Login as a item depositor for this collection, go to new Item page, and store the druid of the new Item.
    sign_in(archivist1)
    visit new_hydrus_item_path(collection: @hc_druid)
    expect(current_path).to match(@edit_path_regex)
    druid = @edit_path_regex.match(current_path)[1]
    # Fill in form and save.
    fill_in 'hydrus_item_contributors_0_name', with: ni.contributor
    fill_in 'Title of item', with: ni.title
    select 'everyone', from: 'hydrus_item_embarg_visib_visibility'
    select 'CC BY-ND Attribution-NoDerivs', from: 'hydrus_item_license'
    click_button(@buttons[:save])
    expect(find(@div_alert)).to have_content(@notices[:save])
    # The view page should display some validation error messages, and should not
    # offer the Publish button.
    expect(find(@div_actions)).not_to have_button(@buttons[:publish_directly])
    expect(find(@span_status)).to have_content(@status_msgs[:draft])
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('draft')
    expect(item.is_publishable).to eq(false)
    expect(item.is_published).to eq(false)
    expect(item.is_returned).to eq(false)
    expect(item.is_destroyable).to eq(true)
    expect(item.accepted_terms_of_deposit).to eq('false')
    expect(item.valid?).to eq(true) # Because unpublished, so validation is limited.

    # Go back to edit page and fill in required elements.
    should_visit_edit_page(item)
    check 'release_settings'
    fill_in 'hydrus_item_abstract', with: ni.abstract
    fill_in 'hydrus_item_contact',  with: ni.contact
    fill_in 'hydrus_item_keywords', with: ni.keywords
    fill_in 'hydrus_item_dates_date_created', with: ni.date_created
    f = Hydrus::ObjectFile.new
    f.pid = druid
    f.file = Tempfile.new('mock_HydrusObjectFile_')
    f.save
    click_button(@buttons[:save])
    expect(find(@div_alert)).to have_content(@notices[:save])
    # The view page should not offer the Publish button since we haven't accepted the terms yet
    expect(find(@div_actions)).not_to have_button(@buttons[:publish_directly])

    # Accept terms of deposit
    should_visit_edit_page(item)
    check 'terms_of_deposit_checkbox'
    click_button(@buttons[:save])

    visit hydrus_item_path(id: item.pid)
    # now we should have the publish button
    expect(find(@div_actions)).to have_button(@buttons[:publish_directly])
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('draft')
    expect(item.is_publishable).to eq(true)
    expect(item.is_publishable_directly).to eq(true)
    expect(item.requires_human_approval).to eq('no')
    expect(item.is_submittable_for_approval).to eq(false)
    expect(item.is_published).to eq(false)
    expect(item.is_returned).to eq(false)
    expect(item.is_destroyable).to eq(true)
    expect(item.valid?).to eq(true)
    # Publish thte item
    click_button(@buttons[:publish_directly])
    expect(find(@div_alert)).to have_content(@notices[:publish_directly])
    # The view page should not offer the Publish button.
    expect(find(@div_actions)).not_to have_button(@buttons[:publish_directly])
    expect(find(@span_status)).to have_content(@status_msgs[:published])
    # Check various Item attributes and methods.
    item = Hydrus::Item.find(druid)
    expect(item.object_status).to eq('published')
    expect(item.is_publishable).to eq(false)
    expect(item.is_published).to eq(true)
    expect(item.is_returned).to eq(false)
    expect(item.is_destroyable).to eq(false)
    expect(item.valid?).to eq(true)
    ps = { visibility: 'world', license_code: 'cc-by-nd', embargo_date: '' }
    check_emb_vis_lic(item, ps)

    # Return to edit page, and try to save Item with an empty title.
    should_visit_edit_page(item)
    fill_in 'hydrus_item_title', with: ''
    click_button(@buttons[:save])
    expect(find(@div_alert)).not_to have_content(@notices[:save])
    expect(find(@div_alert)).to have_content('Title cannot be blank')
    # Fill in the title and save.
    fill_in 'hydrus_item_title', with: ni.title
    click_button(@buttons[:save])
    expect(find(@div_alert)).to have_content(@notices[:save])

    # Check events.
    es = item.get_hydrus_events
    expect(es.map(&:text)).to match_array [
      /\AItem created/,
      /\AItem modified/,
      /\AItem modified/,
      /\ATerms of deposit accepted/,
      /\AItem published/,
    ]
  end

  describe('terms of acceptance for an existing item', integration: true) do
    subject { Hydrus::Item.find('druid:oo000oo0001') }

    it 'should indicate if the item has had terms accepted already' do
      expect(subject.accepted_terms_of_deposit).to eq('true')
      expect(subject.terms_of_deposit_accepted?).to eq(true)
    end

    it 'should indicate the users who have accepted the terms of deposit for this collection in a hash and should returns dates accepted' do
      users = subject.collection.users_accepted_terms_of_deposit
      expect(users.class).to eq(Hash)
      expect(users.size).to eq(2)
      expect(users.keys.include?('archivist1')).to eq(true)
      expect(users['archivist1']).to eq('2011-09-02T09:02:32Z')
      expect(users.keys.include?('archivist3')).to eq(true)
      expect(users['archivist3']).to eq('2012-05-02T20:02:44Z')
    end
  end

  describe 'licenses' do
    before(:each) do
      @lic_select = 'select#hydrus_item_license'
    end

    it 'collection: no license: new items should have no license' do
      sign_in(archivist1)
      # Set collection to no-license mode.
      coll = Hydrus::Collection.find(@hc_druid)
      coll.license_option = 'none'
      coll.license = 'none'
      coll.save
      # Create a new item: page should not offer the license selector.
      druid = should_visit_new_item_page(@hc_druid)
      expect(page).not_to have_css(@lic_select)
      expect(page).to have_content('No license')
    end

    it 'collection: fixed license: new items should have that license' do
      sign_in(archivist1)
      # Set collection to fixed-license mode.
      coll = Hydrus::Collection.find(@hc_druid)
      coll.license_option = 'fixed'
      coll.license = 'cc-by-nd'
      coll.save
      # Create a new item: page should not offer the license selector.
      druid = should_visit_new_item_page(@hc_druid)
      expect(page).not_to have_css(@lic_select)
      expect(page).to have_content('CC BY-ND Attribution-NoDerivs')
    end

    describe 'collection: variable license' do
      it 'with a license: new items offer selector, with default selected' do
        sign_in(archivist1)
        # Set collection to variable-license mode.
        coll = Hydrus::Collection.find(@hc_druid)
        coll.license_option = 'varies'
        coll.license = 'odc-by'
        coll.save
        # Create a new item: page should offer the license selector.
        druid = should_visit_new_item_page(@hc_druid)
        expect(page).to have_css(@lic_select)
        within(@lic_select) {
          nodes = all('option[selected]')
          expect(nodes.size).to eq(1)
          expect(nodes.first.text).to eq('ODC-By Attribution License')
        }
      end

      it 'with no license: new items offer selector, with no-license selected' do
        sign_in(archivist1)
        # Set collection to variable-license mode.
        coll = Hydrus::Collection.find(@hc_druid)
        coll.license_option = 'varies'
        coll.license = 'none'
        coll.save
        # Create a new item: page should offer the license selector.
        druid = should_visit_new_item_page(@hc_druid)
        expect(page).to have_css(@lic_select)
        within(@lic_select) {
          nodes = all('option[selected]')
          expect(nodes.size).to eq(1)
          expect(nodes.first.text).to eq('No license')
        }
      end
    end
  end

  describe 'delete()' do
    it 'should raise error if object is not destroyable' do
      hi = Hydrus::Item.find('druid:oo000oo0001')
      expect(hi.is_destroyable).to eq(false)
      expect { hi.delete }.to raise_error(RuntimeError)
    end

    it 'should fully delete item: from fedora, solr, workflows, DB, and files' do
      # Setup.
      hyi = Hydrus::Item
      hyc = Hydrus::Collection
      afe = ActiveFedora::ObjectNotFoundError
      wfs = Dor::Config.workflow.client
      hwf = Dor::Config.hydrus.app_workflow.to_s
      # Create a new item.
      hi  = create_new_item()
      pid = hi.pid
      dir = hi.content_directory
      # Confirm existence of object:
      #   - in Fedora
      #   - in SOLR
      #   - in workflows
      expect(hi.class).to eq(hyi)
      expect(hyc.all_hydrus_objects(models: [hyi], pids_only: true)).to include(pid)
      expect(wfs.workflows(pid)).to eq([hwf])
      #   - with an uploaded file
      #   - and a corresponding entry in DB table
      expect(Dir.glob(dir + '/*').size).to eq(1)
      expect(Hydrus::ObjectFile.where(pid: pid).size).to eq(1)
      # Delete the Item.
      expect(hi.is_destroyable).to eq(true)
      first(:link, 'Discard this item').click
      click_button 'Discard'
      hi = nil
      # Confirm that object was deleted:
      #   - from Fedora
      #   - from SOLR
      #   - from workflows
      expect { hyi.find(pid) }.to raise_error(afe)
      expect(hyc.all_hydrus_objects(models: [hyi], pids_only: true)).not_to include(pid)
      expect(wfs.workflows(pid)).to eq([])
      #   - with no upload directory
      #   - and no DB entries
      expect(File.directory?(dir)).to eq(false)
      expect(Hydrus::ObjectFile.where(pid: pid).size).to eq(0)
    end
  end
end
