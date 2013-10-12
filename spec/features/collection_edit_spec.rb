require 'spec_helper'

describe("Collection edit", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @druid          = 'druid:oo000oo0003'
    @druid_no_files = 'druid:oo000oo0004'
    @hc             = Hydrus::Collection.find @druid
    @buttons = {
      :sign_in  => 'Sign in',
      :save     => 'save_nojs',
      :add_link => 'Add anothoer link',
      :open     => 'Open Collection',
      :close    => 'Close Collection',
    }
  end

  it "if not logged in, should be redirected to the login page, then back to our intended page after logging in" do
    logout
    visit edit_polymorphic_path(@hc)
    current_path.should == new_user_session_path
    fill_in "Email", :with => 'archivist1@example.com'
    fill_in "Password", :with => login_pw
    click_button "Sign in"
    current_path.should == edit_polymorphic_path(@hc)
  end

  it "can edit Collection descMetadata content" do

    new_abstract  = '  foobarfubb '
    orig_abstract = @hc.abstract
    new_contact   = 'ted@gonzo.com'
    orig_contact  = @hc.contact

    login_as('archivist1')
    should_visit_edit_page(@hc)

    page.should have_content(orig_abstract)
    page.should have_xpath("//input[@value='#{orig_contact}']")

    page.should_not have_content(new_abstract)
    page.should have_no_xpath("//input[@value='#{new_contact}']")
    fill_in "Description", :with => new_abstract
    fill_in "hydrus_collection_contact", :with => new_contact
    click_button "save_nojs"

    current_path.should == polymorphic_path(@hc)
    visit polymorphic_path(@hc)
    page.should have_content(new_abstract.strip)
  end

  it "does not shows deletion link for a collection if it has any items in it" do
    login_as('archivist1')
    should_visit_edit_page(@hc)
    page.should_not have_css(".discard-item")
  end

  it "does not shows deletion link for a collection if has no items but is stil open" do
    login_as('archivist1')
    @hc = Hydrus::Collection.find(@druid_no_files)
    should_visit_edit_page(@hc)
    page.should_not have_css(".discard-item")
  end

  it "can edit and delete multi-valued fields" do
    new_url = "http://library.stanford.edu"
    new_label = "Library Website"
    new_url_field = "hydrus_collection_related_item_url_2"
    new_label_field = "hydrus_collection_related_item_title_2"
    new_delete_link = "remove_relatedItem_2"
    original_url_field = "hydrus_collection_related_item_url_1"
    original_label_field = "hydrus_collection_related_item_title_1"

    login_as('archivist1')
    should_visit_edit_page(@hc)

    page.should_not have_css("##{new_url_field}")
    page.should_not have_css("##{new_label_field}")
    page.should_not have_css("##{new_delete_link}")

    page.should have_css("##{original_url_field}")
    page.should have_css("##{original_label_field}")

    page.should_not have_content new_url
    page.should_not have_content new_label

    click_button "Add another link"
    current_path.should == edit_polymorphic_path(@hc)

    page.should have_css("##{new_url_field}")
    page.should have_css("##{new_label_field}")
    page.should have_css("##{new_delete_link}")

    fill_in("hydrus_collection_related_item_url_2", :with => new_url)
    fill_in("hydrus_collection_related_item_title_2", :with => new_label)

    click_button "save_nojs"
    current_path.should == polymorphic_path(@hc)

    page.should have_content(new_label)

    should_visit_edit_page(@hc)

    page.should have_css("##{new_url_field}")
    page.should have_css("##{new_label_field}")
    page.should have_css("##{new_delete_link}")

    click_link new_delete_link

    current_path.should == edit_polymorphic_path(@hc)

    page.should_not have_css("##{new_url_field}")
    page.should_not have_css("##{new_label_field}")
    page.should_not have_css("##{new_delete_link}")

  end

  it "can edit license content" do
    # Setup and login.
    orig_license        = @hc.license         # original value = cc-by, will set to: odc-odbl
    orig_license_label  = "CC BY Attribution"
    orig_license_option = @hc.license_option  # original value = fixed, will set to: varies
    orig_check_field    = "hydrus_collection_license_option_#{orig_license_option}"
    new_license         = 'odc-odbl'
    new_license_label   = 'ODC-ODbl Open Database License'
    new_license_option  = 'varies'
    new_check_field     = "hydrus_collection_license_option_#{new_license_option}"
    ps={:visibility=>'stanford',:license_code=>'cc-by',:embargo_date=>''}
    check_emb_vis_lic(@hc,ps)

    login_as('archivist1')
    # Visit edit page, and confirm content.
    should_visit_edit_page(@hc)
    page.should have_checked_field(orig_check_field)
    page.has_select?("license_option_#{orig_license_option}", :selected => orig_license_label).should == true
    find_field("license_option_#{orig_license_option}").value.should == 'cc-by'
    page.has_select?("license_option_#{new_license_option}", :selected => []).should == true
    # Make changes, save, and confirm redirect.
    choose(new_check_field)
    select(new_license_label, :from => "license_option_#{new_license_option}")
    click_button "save_nojs"
    current_path.should == polymorphic_path(@hc)
    # Visit view page, and confirm that changes occured.
    visit polymorphic_path(@hc)
    @hc = Hydrus::Collection.find @druid
    ps={:visibility=>'stanford',:license_code=>'odc-odbl',:embargo_date=>''}
    check_emb_vis_lic(@hc,ps)
    confirm_rights_metadata_in_apo(@hc)
  end

  it "can edit embargo content" do
    # Setup and login.
    orig_embargo        = @hc.embargo_terms   # original value = 1 year, will set to 3 years
    orig_embargo_option = @hc.embargo_option  # original value = varies, will set to fixed
    orig_check_field    = "hydrus_collection_embargo_option_#{orig_embargo_option}"
    new_embargo         = '3 years'
    new_embargo_option  = 'fixed'
    new_check_field     = "hydrus_collection_embargo_option_#{new_embargo_option}"
    no_embargo_option   = 'none'
    no_embargo          = ''
    no_embargo_check_field    = "hydrus_collection_embargo_option_#{no_embargo_option}"
    ps={:visibility=>'stanford',:license_code=>'cc-by',:embargo_date=>''}
    check_emb_vis_lic(@hc,ps)
    login_as('archivist1')
    # Visit edit page, and confirm content.
    should_visit_edit_page(@hc)
    page.should have_checked_field(orig_check_field)
    page.has_select?('embargo_option_varies').should == true
    page.has_select?('embargo_option_varies', :selected => "#{orig_embargo} after deposit").should == true
    page.has_select?('embargo_option_fixed', :selected => []).should == true
    # Make changes, save, and confirm redirect.
    choose(new_check_field)
    select(new_embargo, :from => "embargo_option_#{new_embargo_option}")
    click_button "save_nojs"
    current_path.should == polymorphic_path(@hc)
    # Visit view-page, and confirm that changes occured.
    visit polymorphic_path(@hc)
    # Undo changes, and confirm.
    should_visit_edit_page(@hc)
    page.has_select?('embargo_option_varies', :selected => []).should == true
    page.has_select?('embargo_option_fixed', :selected => "#{new_embargo} after deposit").should == true
    choose(orig_check_field)
    select(orig_embargo, :from => "embargo_option_#{orig_embargo_option}")
    click_button "save_nojs"
    current_path.should == polymorphic_path(@hc)
    # Set to no embargo after embargo was previously set and ensure there is no longer an embargo period set.
    should_visit_edit_page(@hc)
    page.has_select?('embargo_option_varies', :selected => "#{orig_embargo} after deposit").should == true
    choose(no_embargo_check_field)
    click_button "save_nojs"
    current_path.should == polymorphic_path(@hc)
    find("div.collection-settings").should_not have_content(orig_embargo)
    # verify embargo is now 'none' and terms are not set
    @hc = Hydrus::Collection.find @druid
    @hc.embargo_option.should == 'none'
    @hc.embargo_terms.should == ''
    confirm_rights_metadata_in_apo(@hc)
  end

  context "modifying persons and roles" do

    def check_role_management_div(role_info)
      # Takes a role info hash, like that returned by apo_person_roles().
      # Confirms that the role-management section of the current page
      # contains same information.
      rmdiv = find('div#role-management-wth-reviewers')
      dk    = 'hydrus_collection_apo_person_roles'
      got   = {}
      Hydrus::Responsible.role_labels(:collection_level).each do |role, h|
        ids = rmdiv.find("input[id^='#{dk}[#{role}]']")[:value]
        ids = Hydrus::ModelHelper.parse_delimited(ids)
        got[role] = Set.new(ids) if ids.length > 0
      end
      got.should == role_info
    end

    it "should be able to add/remove persons with various roles" do
      # Visit edit page.
      login_as('archivist1')
      should_visit_edit_page(@hc)
      # Check the initial role-management section.
      role_info = @hc.apo_person_roles
      check_role_management_div(role_info)
      # Modify the roles in the UI.
      role_info = {
        'hydrus-collection-manager'        => Set.new(%w(aa bb archivist1)),
        'hydrus-collection-reviewer'       => Set.new(%w(cc dd ee)),
        'hydrus-collection-item-depositor' => Set.new(%w(ff)),
        'hydrus-collection-viewer'         => Set.new(%w(gg hh ii)),
        'hydrus-collection-depositor'      => Set.new(%w(archivist3)),
      }
      rmdiv = find('div#role-management-wth-reviewers')
      dk    = 'hydrus_collection_apo_person_roles'
      role_info.each do |role,ids|
        rmdiv.fill_in("#{dk}[#{role}]", :with => ids.to_a.join(', '))
      end
      # Check role-management section after additions.
      click_button "save_nojs"
      should_visit_edit_page(@hc)
      check_role_management_div(role_info)
      # Confirm new content in fedora.
      @hc = Hydrus::Collection.find @druid
      @hc.apo_person_roles.should == role_info
      confirm_rights_metadata_in_apo(@hc)
    end

    it "should be able to strip email addresses to leave just sunetIDs from persons with various roles" do
      # Visit edit page.
      login_as('archivist1')
      should_visit_edit_page(@hc)
      # Check the initial role-management section.
      role_info = @hc.apo_person_roles
      check_role_management_div(role_info)
      # Modify the roles in the UI.
      role_info = {
        'hydrus-collection-manager'        => Set.new(%w(aa@crapola.com bb archivist1)),
        'hydrus-collection-reviewer'       => Set.new(%w(cc dd ee@dude.com)),
        'hydrus-collection-item-depositor' => Set.new(%w(ff@yoyo.com)),
        'hydrus-collection-viewer'         => Set.new(%w(gg hh ii@wazzzup.org)),
        'hydrus-collection-depositor'      => Set.new(%w(archivist3@i.am.a.stupid.domainname.com)),
      }
      role_info_stripped = {
        'hydrus-collection-manager'        => Set.new(%w(aa bb archivist1)),
        'hydrus-collection-reviewer'       => Set.new(%w(cc dd ee)),
        'hydrus-collection-item-depositor' => Set.new(%w(ff)),
        'hydrus-collection-viewer'         => Set.new(%w(gg hh ii)),
        'hydrus-collection-depositor'      => Set.new(%w(archivist3)),
      }
      rmdiv = find('div#role-management-wth-reviewers')
      dk    = 'hydrus_collection_apo_person_roles'
      role_info.each do |role,ids|
        rmdiv.fill_in("#{dk}[#{role}]", :with => ids.to_a.join(', '))
      end
      # Check role-management section after additions.
      click_button "save_nojs"
      should_visit_edit_page(@hc)
      check_role_management_div(role_info_stripped)
      # Confirm new content in fedora.
      @hc = Hydrus::Collection.find @druid
      @hc.apo_person_roles.should == role_info_stripped
      confirm_rights_metadata_in_apo(@hc)
    end

  end

  describe "emails" do

    describe "send_publish_email_notification()" do

      before(:each) do
        @coll = Hydrus::Collection.new
        @coll.admin_policy_object = Hydrus::AdminPolicyObject.new
      end

      it "should send open email when there are item depositors" do
        @coll.apo_person_roles = {:"hydrus-collection-item-depositor" => "jdoe"}
        e = expect { @coll.send_publish_email_notification(true) }
        e.to change { ActionMailer::Base.deliveries.count }.by(1)
        email = ActionMailer::Base.deliveries.last
        email.to.should == ["jdoe@stanford.edu"]
        email.subject.should =~ /^Collection opened for deposit/
      end

      it "should send close email when there are item depositors" do
        @coll.apo_person_roles = {:"hydrus-collection-item-depositor" => "jdoe"}
        e = expect { @coll.send_publish_email_notification(false) }
        e.to change { ActionMailer::Base.deliveries.count }.by(1)
        email = ActionMailer::Base.deliveries.last
        email.to.should == ["jdoe@stanford.edu"]
        email.subject.should =~ /Collection closed for deposit/
      end

      it "should not send an email when there are no item depositors" do
        e = expect {@coll.send_publish_email_notification(true)}
        e.to change { ActionMailer::Base.deliveries.count }.by(0)
        e = expect {@coll.send_publish_email_notification(false)}
        e.to change { ActionMailer::Base.deliveries.count }.by(0)
      end

    end

    describe "when updating a collection" do

      before(:each) do
        @prev_mint_ids = config_mint_ids()
      end

      after(:each) do
        config_mint_ids(@prev_mint_ids)
      end

      it "should send an email to managers when we're opening a collection and to a depositor when we add them" do
        login_as('archivist1')
        visit new_hydrus_collection_path()
        fill_in "hydrus_collection_title", :with => "TestingTitle"
        fill_in "hydrus_collection_abstract", :with => "Summary of my content"
        fill_in "hydrus_collection_contact", :with => "jdoe@example.com"
        click_button("save_nojs")
        page.should have_content("Your changes have been saved.")

        expect {click_button("Open Collection")}.to change { ActionMailer::Base.deliveries.count }.by(1)

        email = ActionMailer::Base.deliveries.last
        email.to.should == ["archivist1@stanford.edu"]
        email.subject.should == "Collection opened for deposit in the Stanford Digital Repository"
        
        click_link("Edit Collection")

        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jdoe"
        
        expect {click_button("save_nojs")}.to change { ActionMailer::Base.deliveries.count }.by(1)
        email = ActionMailer::Base.deliveries.last
        email.to.should == ["jdoe@stanford.edu"]
        email.subject.should == "Invitation to deposit in the Stanford Digital Repository"       
      end

      it "should not send an email to new depositors when we're updating a collection if user does not check the send email checkbox" do
        login_as('archivist1')
        visit new_hydrus_collection_path()
        fill_in "hydrus_collection_title", :with => "TestingTitle"
        fill_in "hydrus_collection_abstract", :with => "Summary of my content"
        fill_in "hydrus_collection_contact", :with => "jdoe@example.com"
        click_button("save_nojs")
        page.should have_content("Your changes have been saved.")
        click_button("Open Collection")
        click_link("Edit Collection")

        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jdoe"
        uncheck("should_send_role_change_emails")
        
        expect {click_button("save_nojs")}.to change { ActionMailer::Base.deliveries.count }.by(0)
      end
      
      it "should handle complex changes to depositors" do
        login_as('archivist1')
        visit new_hydrus_collection_path()
        fill_in "hydrus_collection_title", :with => "TestingTitle"
        fill_in "hydrus_collection_abstract", :with => "Summary of my content"
        fill_in "hydrus_collection_contact", :with => "jdoe@example.com"
        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jdoe, leland, janedoe"
        click_button("save_nojs")
        page.should have_content("Your changes have been saved.")
        click_button("Open Collection")
        click_link("Edit Collection")

        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jandoe, leland, jondoe"
        expect {click_button("save_nojs")}.to change { ActionMailer::Base.deliveries.count }.by(2) # a removal notice for jdoe,jandoe and an invitation notice jandoe and jondoe
        email = ActionMailer::Base.deliveries.last
        email.to.should == ["jdoe@stanford.edu", "janedoe@stanford.edu"]
        email.subject.should == "Removed as a depositor in the Stanford Digital Repository"
      end

      it "should not send an email if the collection is closed" do
        login_as('archivist1')
        visit new_hydrus_collection_path()
        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jdoe"
        expect {click_button("save_nojs")}.to change { ActionMailer::Base.deliveries.count }.by(0)
      end

    end
  end

  describe "role-protection" do

    before(:each) do
      @prev_mint_ids = config_mint_ids()
    end

    after(:each) do
      config_mint_ids(@prev_mint_ids)
    end

    it "action buttons should not be accessible to users with insufficient powers" do
      # Create a collection.
      owner  = 'archivist2'
      viewer = 'archivist6'
      opts = {
        :user    => owner,
        :viewers => viewer,
      }
      hc = create_new_collection(opts)
      # Should see the open collection button.
      login_as(owner)
      should_visit_view_page(hc)
      page.should have_button(@buttons[:open])
      # But another user should not see the button.
      login_as(viewer)
      should_visit_view_page(hc)
      page.should_not have_button(@buttons[:open])
      # Open the collection. Should see close button.
      login_as(owner)
      should_visit_view_page(hc)
      click_button(@buttons[:open])
      page.should have_button(@buttons[:close])
      # But another user should not see the button.
      login_as(viewer)
      should_visit_view_page(hc)
      page.should_not have_button(@buttons[:close])
    end

  end

  it "form should enforce license selection for license options varies and fixed" do
    %w(varies fixed).each do |opt|
      # Set collection to no-license mode.
      @hc.license_option = 'none'
      @hc.license = 'none'
      @hc.save
      # Some values we need.
      vs = {
        :radio    => "hydrus_collection_license_option_#{opt}",
        :select   => "license_option_#{opt}",
        :lic_txt  => "ODC-ODbl Open Database License",
        :alert    => "div.alert",
        :msg_err  => 'License must be specified',
        :msg_save => 'Your changes have been saved',
      }
      # Edit collection, but forget to choose a license.
      login_as('archivist1')
      should_visit_edit_page(@hc)
      choose(vs[:radio])
      click_button(@buttons[:save])
      # We should still be on edit page, with a flash error.
      page.should have_css("input#" + vs[:radio])
      find(vs[:alert]).should have_content(vs[:msg_err])
      # Select a license and save -- much success.
      select(vs[:lic_txt], :from => vs[:select])
      click_button(@buttons[:save])
      find(vs[:alert]).should have_content(vs[:msg_save])
    end
  end

end
