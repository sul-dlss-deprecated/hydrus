require 'spec_helper'

describe("Item versioning", :type => :request, :integration => true) do

  fixtures :users

  before :each do
    @hi = Hydrus::Item.find('druid:oo000oo0001')
    @ok_notice = "Your changes have been saved."
    @buttons = {
      :save                => 'Save',
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
    Dor::WorkflowService.delete_workflow('dor', p, 'versioningWF')
    Dor::WorkflowService.delete_workflow('dor', p, wf)
    Dor::WorkflowService.create_workflow('dor', p, wf, wf_xml)
  end

  it "item view page should display version info" do
    login_as('archivist1')
    should_visit_view_page(@hi)
    item_deets = find('dl.item-view')
    item_deets.should have_content('Version')
    item_deets.should have_content(@hi.version_tag)
  end

  it "if item is initial version, should not offer version info on the editing page" do
    @hi.is_initial_version.should == true
    login_as('archivist1')
    should_visit_edit_page(@hi)
    page.should_not have_css('textarea#hydrus_item_version_description')
  end

  it "should be able to open a new version" do
    # Before-assertions.
    @hi.is_initial_version.should == true
    @hi.version_tag.should == 'v1.0.0'
    @hi.version_significance.should == :major
    @hi.version_description.should == 'Initial Version'
    @hi.version_started_time.should == '2012-11-01T00:00:22Z'
    @hi.object_status.should == 'published'
    @hi.prior_license.should == nil
    n_events = @hi.get_hydrus_events.size
    wf_steps = %w(submit approve)
    wf_steps.each { |s| @hi.workflows.workflow_step_is_done(s).should == true }

    # Open new version.
    login_as('archivist1')
    should_visit_view_page(@hi)
    click_button(@buttons[:open_new_version])

    # Assertions after opening new version.
    @hi = Hydrus::Item.find(@hi.pid)
    @hi.is_initial_version.should == false
    @hi.version_tag.should == 'v2.0.0'
    @hi.version_significance.should == :major
    @hi.version_description.should == ''
    @hi.version_started_time[0..9].should == HyTime.now_date
    @hi.object_status.should == 'draft'
    @hi.prior_license.should == @hi.license
    es = @hi.get_hydrus_events
    es.size.should == n_events + 1
    es.last.text.should == 'New version opened'
    wf_steps.each { |s| @hi.workflows.workflow_step_is_done(s).should == false }

    # View page should not offer the Publish button, because the user
    # needs to fill in a version description.
    should_visit_view_page(@hi)
    page.should_not have_button(@buttons[:publish_directly])

    # Add the version info.
    should_visit_edit_page(@hi)
    fill_in("hydrus_item_version_description", :with => 'Blah blah')
    choose("Minor")
    click_button(@buttons[:save])

    # Assertions after adding version description.
    @hi = Hydrus::Item.find(@hi.pid)
    @hi.is_initial_version.should == false
    @hi.version_tag.should == 'v1.1.0'
    @hi.version_significance.should == :minor
    @hi.version_description.should == 'Blah blah'
    @hi.version_started_time[0..9].should == HyTime.now_date
    @hi.object_status.should == 'draft'

    # Now we can click the the Publish button, which closes the version.
    should_visit_view_page(@hi)
    page.should have_button(@buttons[:publish_directly])
    click_button(@buttons[:publish_directly])

    # Assertions after adding version description.
    @hi = Hydrus::Item.find(@hi.pid)
    wf_steps.each { |s| @hi.workflows.workflow_step_is_done(s).should == true }
    @hi.object_status.should == 'published'

    # View page should offer open version button.
    should_visit_view_page(@hi)
    click_button(@buttons[:open_new_version])

    # Assertions after opening new version.
    @hi = Hydrus::Item.find(@hi.pid)
    @hi.version_tag.should == 'v2.0.0'
  end

  it "changing license should force user to select :major version" do
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
    find("div.alert").should have_content("Version must be 'major'")
    @hi = Hydrus::Item.find(@hi.pid)
    @hi.license.should == orig_lic
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
        page.should have_selector(@vis_sel_css)
      end

      it "collection in visibility-fixed mode: do not offer visibility drop-down" do
        # Set the item's collection to visibility-varies mode.
        coll = @hi.collection
        coll.visibility_option = 'fixed'
        coll.save
        # Go to edit page.
        login_as('archivist1')
        should_visit_edit_page(@hi)
        page.should_not have_selector(@vis_sel_css)
      end

    end

    describe "subsequent version" do

      it "prior visibility = world: do not offer drop-down" do
        # Set visibility to world.
        @hi.visibility = 'world'
        @hi.save
        # Open new version.
        login_as('archivist1')
        should_visit_view_page(@hi)
        click_button(@buttons[:open_new_version])
        # Edit page should not offer ability to change visibility.
        should_visit_edit_page(@hi)
        page.should_not have_selector(@vis_sel_css)
      end

      it "prior visibility = stanford: offer drop-down" do
        # Set visibility to world.
        @hi.visibility = 'stanford'
        @hi.save
        # Open new version.
        login_as('archivist1')
        should_visit_view_page(@hi)
        click_button(@buttons[:open_new_version])
        # Edit page should not offer ability to change visibility.
        should_visit_edit_page(@hi)
        page.should have_selector(@vis_sel_css)
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
        :flash      => 'div.alert',
        :err_range  => 'Embargo date must be in the range',
        :err_format => 'Embargo date must be in yyyy-mm-dd',
      }
    end

    it "initial version never embargoed: should not be able to add an embargo" do
      # Open new version.
      login_as('archivist1')
      should_visit_view_page(@hi)
      click_button(@buttons[:open_new_version])
      # Edit page should not offer ability to add an embargo.
      should_visit_edit_page(@hi)
      page.should_not have_selector(@vs[:date])
    end

    it "should be able to modify existing embargo (with valid dates) or even remove it" do
      # Confirm initial status.
      @hi.is_embargoed.should == false
      @hi.visibility.should == ['world']
      @hi.collection.embargo_terms.should == '1 year'
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
      @hi.save.should == true
      # Confirm changes.
      @hi = Hydrus::Item.find(@hi.pid)
      @hi.is_embargoed.should == true
      @hi.visibility.should == ['world']
      @hi.initial_submitted_for_publish_time.should == pds
      # Open new version.
      login_as('archivist1')
      should_visit_view_page(@hi)
      click_button(@buttons[:open_new_version])
      # Edit page should offer ability to add an embargo.
      should_visit_edit_page(@hi)
      page.should have_selector(@vs[:date_sel])
      # 1. Try to set an embargo too far into the future.
      choose(@vs[:yes])
      fill_in(@vs[:date], :with => HyTime.date(pd + 1.year + 2.day))
      click_button(@buttons[:save])
      find(@vs[:flash]).should have_content(@vs[:err_range])
      # 2. Try to set an embargo with a malformed date.
      choose(@vs[:yes])
      fill_in(@vs[:date], :with => 'foobar')
      click_button(@buttons[:save])
      find(@vs[:flash]).should have_content(@vs[:err_format])
      # 3a. Should be able to set a valid embargo date, farther into future.
      choose(@vs[:yes])
      fill_in(@vs[:date], :with => HyTime.date(ed + 1.month))
      click_button(@buttons[:save])
      find(@vs[:flash]).should have_content(@ok_notice)
      # 3b. Should be able to set a valid embargo date, closer to today.
      should_visit_edit_page(@hi)
      choose(@vs[:yes])
      fill_in(@vs[:date], :with => HyTime.date(ed - 1.month))
      click_button(@buttons[:save])
      find(@vs[:flash]).should have_content(@ok_notice)
      # Confirm that we set the embargo, and did not alter visibility.
      @hi = Hydrus::Item.find(@hi.pid)
      @hi.is_embargoed.should == true
      @hi.visibility.should == ['world']
      # 4. Should be able to remove the embargo entirely.
      should_visit_edit_page(@hi)
      choose(@vs[:no])
      click_button(@buttons[:save])
      find(@vs[:flash]).should have_content(@ok_notice)
      # Confirm changes.
      @hi = Hydrus::Item.find(@hi.pid)
      @hi.is_embargoed.should == false
      @hi.visibility.should == ['world']
    end

    it "should not be able to modify embargo if the embargo window has passed" do
      # Confirm initial status.
      @hi.is_embargoed.should == false
      @hi.visibility.should == ['world']
      @hi.collection.embargo_terms.should == '1 year'
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
      @hi.save.should == true
      # Confirm changes.
      @hi = Hydrus::Item.find(@hi.pid)
      @hi.is_embargoed.should == true
      @hi.visibility.should == ['world']
      @hi.initial_submitted_for_publish_time.should == pds
      # Open new version.
      login_as('archivist1')
      should_visit_view_page(@hi)
      click_button(@buttons[:open_new_version])
      # Edit page should not offer ability to modify the embargo.
      should_visit_edit_page(@hi)
      page.should_not have_selector(@vs[:date_sel])
    end

  end

end
