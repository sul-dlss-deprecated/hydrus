require 'spec_helper'

describe("Item versioning", :type => :request, :integration => true) do

  fixtures :users

  before :each do
    @hi = Hydrus::Item.find('druid:oo000oo0001')
    @ok_notice = "Your changes have been saved."
    @item_discard = ".icon-trash"
    @buttons = {
      :save                => 'save_nojs',
      :publish_directly    => 'Publish',
      :open_new_version    => 'Open new version',
    }
  end

  # NOTE: We need this after() block because our typical approach of relying
  # on Rubydora transactions does not restore the versioning status of the
  # object back to initial conditions. Rubydora's rollback() affects Fedora,
  # not the workflow service. The latter controls versioning. For most Hydrus
  # operations, we don't care about workflows because we never read from
  # there; we only advance workflow to the next step. In case case of
  # versioning, we (especially dor-services gem) must read from workflows.
  #
  # The rake task :refresh_workflows duplicates some of this behavior.
  after(:each) do
    p      = @hi.pid
    wf     = Dor::Config.hydrus.app_workflow
    wf_xml = Hydrus.fixture_foxml(p, :is_wf => true)
    Dor::Config.workflow.client.delete_workflow('dor', p, 'versioningWF')
    Dor::Config.workflow.client.delete_workflow('dor', p, wf)
    Dor::Config.workflow.client.create_workflow('dor', p, wf, wf_xml)
  end

  it "initial unpublished version of an item offers discard button" do
    login_as('archivist1')
    item=Hydrus::Item.find('druid:oo000oo0005')
    should_visit_view_page(item)
    expect(page).to have_css(@item_discard) # we are unpublished and on v1, we do have a discard button
    expect(item.is_initial_version).to eq(true)
    expect(item.is_destroyable).to eq(true) # can destroy an initial unpublished version
    expect(item.object_status).not_to eq('published')
  end


  it "item view page should display version info" do
    login_as('archivist1')
    should_visit_view_page(@hi)
    item_deets = find('dl.item-view')
    expect(item_deets).to have_content('Version')
    expect(item_deets).to have_content(@hi.version_tag)
  end

  it "if item is initial version, should not offer version info on the editing page" do
    expect(@hi.is_initial_version).to eq(true)
    login_as('archivist1')
    should_visit_edit_page(@hi)
    expect(page).not_to have_css('textarea#hydrus_item_version_description')
  end

  it "should be able to open a new version" do
    pending
    # Before-assertions.
    expect(@hi.is_initial_version).to eq(true)
    expect(@hi.version_tag).to eq('v1.0.0')
    expect(@hi.version_significance).to eq(:major)
    expect(@hi.version_description).to eq('Initial Version')
    expect(@hi.version_started_time).to eq('2012-11-01T00:00:22Z')
    expect(@hi.object_status).to eq('published')
    expect(@hi.prior_license).to eq(nil)
    expect(@hi.is_destroyable).to eq(false) # cannot destroy a published version
    n_events = @hi.get_hydrus_events.size
    expect(@hi.workflows.workflow_step_is_done('submit')).to eq(true)
    expect(@hi.workflows.workflow_step_is_done('approve')).to eq(true)

    # Open new version.
    login_as('archivist1')
    should_visit_view_page(@hi)
    expect(page).not_to have_css(@item_discard) # we are published and on v1, we do not have a discard button

    click_button(@buttons[:open_new_version])

    # Assertions after opening new version.
    @hi = Hydrus::Item.find(@hi.pid)
    expect(@hi.is_initial_version).to eq(false)
    expect(@hi.version_tag).to eq('v2.0.0')
    expect(@hi.version_significance).to eq(:major)
    expect(@hi.version_description).to eq('')
    expect(@hi.version_started_time[0..9]).to eq(HyTime.now_date)
    expect(@hi.object_status).to eq('draft')
    expect(@hi.prior_license).to eq(@hi.license)
    expect(@hi.is_destroyable).to eq(false)
    es = @hi.get_hydrus_events
    expect(es.size).to eq(n_events + 1)
    expect(es.last.text).to eq('New version opened')
    expect(@hi.workflows.workflow_step_is_done('submit')).to eq(false)
    expect(@hi.workflows.workflow_step_is_done('approve')).to eq(false)

    # View page should not offer the Publish button, because the user
    # needs to fill in a version description.  It should also not offer a discard button since this is v2 and is unpublished
    should_visit_view_page(@hi)
    expect(page).not_to have_css(@item_discard)
    expect(page).not_to have_button(@buttons[:publish_directly])

    # Add the version info.
    should_visit_edit_page(@hi)
    fill_in("hydrus_item_version_description", :with => 'Blah blah')
    choose("Minor")
    click_button(@buttons[:save])

    # Assertions after adding version description.
    @hi = Hydrus::Item.find(@hi.pid)
    expect(@hi.is_initial_version).to eq(false)
    expect(@hi.version_tag).to eq('v1.1.0')
    expect(@hi.version_significance).to eq(:minor)
    expect(@hi.version_description).to eq('Blah blah')
    expect(@hi.version_started_time[0..9]).to eq(HyTime.now_date)
    expect(@hi.object_status).to eq('draft')

    # Now we can click the the Publish button, which closes the version.
    should_visit_view_page(@hi)
    expect(page).to have_button(@buttons[:publish_directly])
    click_button(@buttons[:publish_directly])

    # Assertions after adding version description.
    @hi = Hydrus::Item.find(@hi.pid)
    expect(@hi.workflows.workflow_step_is_done('submit')).to eq(true)
    expect(@hi.workflows.workflow_step_is_done('approve')).to eq(true)
    expect(@hi.object_status).to eq('published')

    # View page should offer open version button.
    should_visit_view_page(@hi)
    expect(page).not_to have_css(@item_discard) # still no discard button
    click_button(@buttons[:open_new_version])

    # Assertions after opening new version.
    @hi = Hydrus::Item.find(@hi.pid)
    expect(@hi.version_tag).to eq('v2.0.0')
    expect(@hi.is_destroyable).to eq(false) # still can't delete it even though its not published, since we are on v2
    expect(@hi.object_status).not_to eq('published')

    should_visit_view_page(@hi)
    expect(page).not_to have_css(@item_discard) # still no discard button even though we are not published, since we are on v2

  end

  it "changing license should force user to select :major version" do
    pending
    # Set the item's collection to license-varies mode.
    orig_lic = 'cc-by'
    coll = @hi.collection
    coll.license_option = 'varies'
    coll.license = orig_lic
    coll.save
    # Open new version.
    login_as('archivist1')
    should_visit_view_page(@hi)
    click_button(@buttons[:open_new_version])
    # Go to edit page:
    #   - change license
    #   - set version to minor
    should_visit_edit_page(@hi)
    fill_in("hydrus_item_version_description", :with => 'Blah blah')
    choose("Minor")
    select("PDDL Public Domain Dedication and License", :from => 'hydrus_item_license')
    # Try to save.
    #   - Should get a flash error message.
    #   - Item's license should be unchanged.
    click_button(@buttons[:save])
    expect(find("#flash-notices div.alert")).to have_content("Version must be 'major'")
    @hi = Hydrus::Item.find(@hi.pid)
    expect(@hi.license).to eq(orig_lic)
  end

  describe "editability of item visibility" do

    before(:each) do
      # Set the item's collection to visibility-varies mode.
      coll = @hi.collection
      coll.visibility_option = 'varies'
      coll.save
      # Some css selectors.
      @vis_css = 'hydrus_item_embarg_visib_visibility'
      @vis_sel_css = 'select#' + @vis_css
    end

    describe "initial version" do

      it "collection in visibility-varies mode: offer visibility drop-down" do
        login_as('archivist1')
        should_visit_edit_page(@hi)
        expect(page).to have_selector(@vis_sel_css)
      end

      it "collection in visibility-fixed mode: do not offer visibility drop-down" do
        # Set the item's collection to visibility-varies mode.
        coll = @hi.collection
        coll.visibility_option = 'fixed'
        coll.save
        # Go to edit page.
        login_as('archivist1')
        should_visit_edit_page(@hi)
        expect(page).not_to have_selector(@vis_sel_css)
      end

    end

    describe "subsequent version" do

      it "prior visibility = world: do not offer drop-down" do
        pending
        # Set visibility to world.
        @hi.visibility = 'world'
        @hi.save
        # Open new version.
        login_as('archivist1')
        should_visit_view_page(@hi)
        click_button(@buttons[:open_new_version])
        # Edit page should not offer ability to change visibility.
        should_visit_edit_page(@hi)
        expect(page).not_to have_selector(@vis_sel_css)
      end

      it "prior visibility = stanford: offer drop-down" do
        pending
        # Set visibility to world.
        @hi.visibility = 'stanford'
        @hi.save
        # Open new version.
        login_as('archivist1')
        should_visit_view_page(@hi)
        click_button(@buttons[:open_new_version])
        # Edit page should not offer ability to change visibility.
        should_visit_edit_page(@hi)
        expect(page).to have_selector(@vis_sel_css)
      end

    end

  end

  describe "embargos" do

    before(:each) do
      @vs = {
        :yes        => 'hydrus_item_embarg_visib_embargoed_yes',
        :no         => 'hydrus_item_embarg_visib_embargoed_no',
        :date       => 'hydrus_item_embarg_visib_date',
        :date_sel   => 'input#hydrus_item_embarg_visib_date',
        :flash      => "#flash-notices div.alert",
        :err_range  => 'Embargo date must be in the range',
        :err_format => 'Embargo date must be in yyyy-mm-dd',
      }
    end

    it "initial version never embargoed: should not be able to add an embargo" do
      pending
      # Open new version.
      login_as('archivist1')
      should_visit_view_page(@hi)
      click_button(@buttons[:open_new_version])
      # Edit page should not offer ability to add an embargo.
      should_visit_edit_page(@hi)
      expect(page).not_to have_selector(@vs[:date])
    end

    it "should be able to modify existing embargo (with valid dates) or even remove it" do
      pending
      # Confirm initial status.
      expect(@hi.is_embargoed).to eq(false)
      expect(@hi.visibility).to eq(['world'])
      expect(@hi.collection.embargo_terms).to eq('1 year')
      # Add an embargo to the Item:
      #   - The Collection allows a max 1-year embargo window.
      #   - Set publish time to 8 months ago.
      #   - Set embargo date to 2 months in future.
      #   - So we still have some window to work with, in both directions.
      pd  = HyTime.now - 8.month
      ed  = HyTime.now + 2.month
      pds = HyTime.datetime(pd)
      @hi.embarg_visib = { 'embargoed' => 'yes', 'date' => HyTime.date(ed) }
      @hi.submitted_for_publish_time = pds
      @hi.initial_submitted_for_publish_time = pds
      expect(@hi.save).to eq(true)
      # Confirm changes.
      @hi = Hydrus::Item.find(@hi.pid)
      expect(@hi.is_embargoed).to eq(true)
      expect(@hi.visibility).to eq(['world'])
      expect(@hi.initial_submitted_for_publish_time).to eq(pds)
      # Open new version.
      login_as('archivist1')
      should_visit_view_page(@hi)
      click_button(@buttons[:open_new_version])
      # Edit page should offer ability to add an embargo.
      should_visit_edit_page(@hi)
      expect(page).to have_selector(@vs[:date_sel])
      # 1. Try to set an embargo too far into the future.
      choose(@vs[:yes])
      fill_in(@vs[:date], :with => HyTime.date(pd + 1.year + 2.day))
      click_button(@buttons[:save])
      expect(find(@vs[:flash])).to have_content(@vs[:err_range])
      # 2. Try to set an embargo with a malformed date.
      choose(@vs[:yes])
      fill_in(@vs[:date], :with => 'foobar')
      click_button(@buttons[:save])
      expect(find(@vs[:flash])).to have_content(@vs[:err_format])
      # 3a. Should be able to set a valid embargo date, farther into future.
      choose(@vs[:yes])
      fill_in(@vs[:date], :with => HyTime.date(ed + 1.month))
      click_button(@buttons[:save])
      expect(find(@vs[:flash])).to have_content(@ok_notice)
      # 3b. Should be able to set a valid embargo date, closer to today.
      should_visit_edit_page(@hi)
      choose(@vs[:yes])
      fill_in(@vs[:date], :with => HyTime.date(ed - 1.month))
      click_button(@buttons[:save])
      expect(find(@vs[:flash])).to have_content(@ok_notice)
      # Confirm that we set the embargo, and did not alter visibility.
      @hi = Hydrus::Item.find(@hi.pid)
      expect(@hi.is_embargoed).to eq(true)
      expect(@hi.visibility).to eq(['world'])
      # 4. Should be able to remove the embargo entirely.
      should_visit_edit_page(@hi)
      choose(@vs[:no])
      click_button(@buttons[:save])
      expect(find(@vs[:flash])).to have_content(@ok_notice)
      # Confirm changes.
      @hi = Hydrus::Item.find(@hi.pid)
      expect(@hi.is_embargoed).to eq(false)
      expect(@hi.visibility).to eq(['world'])
    end

    it "should not be able to modify embargo if the embargo window has passed" do
      pending
      # Confirm initial status.
      expect(@hi.is_embargoed).to eq(false)
      expect(@hi.visibility).to eq(['world'])
      expect(@hi.collection.embargo_terms).to eq('1 year')
      # Add an embargo to the Item:
      #   - The Collection allows a max 1-year embargo window.
      #   - Set publish time to a bit more than a year ago.
      #   - Set embargo date to a few days ago.
      #   - This simulates a item with an embargo window that has passed,
      #     but the embargo-release robot has not yet removed the embargo.
      pd  = HyTime.now - 1.year - 2.day
      ed  = HyTime.now - 3.day
      pds = HyTime.datetime(pd)
      @hi.embarg_visib = { 'embargoed' => 'yes', 'date' => HyTime.date(ed) }
      @hi.submitted_for_publish_time = pds
      @hi.initial_submitted_for_publish_time = pds
      expect(@hi.save).to eq(true)
      # Confirm changes.
      @hi = Hydrus::Item.find(@hi.pid)
      expect(@hi.is_embargoed).to eq(true)
      expect(@hi.visibility).to eq(['world'])
      expect(@hi.initial_submitted_for_publish_time).to eq(pds)
      # Open new version.
      login_as('archivist1')
      should_visit_view_page(@hi)
      click_button(@buttons[:open_new_version])
      # Edit page should not offer ability to modify the embargo.
      should_visit_edit_page(@hi)
      expect(page).not_to have_selector(@vs[:date_sel])
    end

  end

end
