require 'spec_helper'

describe("Collection edit", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @druid          = 'druid:oo000oo0003'
    @druid_no_files = 'druid:oo000oo0004'
    @hc             = Hydrus::Collection.find @druid
  end

  it "if not logged in, should be redirected to home page" do
    logout
    visit edit_polymorphic_path(@hc)
    current_path.should == root_path
  end

  it "can edit Collection descMetadata content" do

    new_abstract  = '  foobarfubb '
    orig_abstract = @hc.abstract
    new_contact   = 'ted@gonzo.com'
    orig_contact  = @hc.contact

    login_as_archivist1
    should_visit_edit_page(@hc)

    page.should have_content(orig_abstract)
    page.should have_xpath("//input[@value='#{orig_contact}']")

    page.should_not have_content(new_abstract)
    page.should have_no_xpath("//input[@value='#{new_contact}']")
    fill_in "Description", :with => new_abstract
    fill_in "hydrus_collection_contact", :with => new_contact
    click_button "Save"

    current_path.should == polymorphic_path(@hc)
    visit polymorphic_path(@hc)
    page.should have_content(new_abstract.strip)
  end

  it "does not shows deletion link for a collection if it has any items in it" do
    login_as_archivist1
    should_visit_edit_page(@hc)
    page.should_not have_css(".discard-item")
  end

  it "does not shows deletion link for a collection if has no items but is stil open" do
    login_as_archivist1
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

    login_as_archivist1
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

    click_button "Save"
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

  it "can edit APO license content" do
    # Setup and login.
    orig_license        = @hc.license         # original value = cc-by, will set to: odc-odbl
    orig_license_label  = "CC BY Attribution"
    orig_license_option = @hc.license_option  # original value = fixed, will set to: varies
    orig_check_field    = "hydrus_collection_license_option_#{orig_license_option}"
    new_license         = 'odc-odbl'
    new_license_label   = 'ODC-ODbl Open Database License'
    new_license_option  = 'varies'
    new_check_field     = "hydrus_collection_license_option_#{new_license_option}"
    login_as_archivist1
    # Visit edit page, and confirm content.
    should_visit_edit_page(@hc)
    page.should have_checked_field(orig_check_field)
    page.has_select?("license_option_#{orig_license_option}", :selected => orig_license_label).should == true
    find_field("license_option_#{orig_license_option}").value.should == 'cc-by'
    page.has_select?("license_option_#{new_license_option}", :selected => nil).should == true
    # Make changes, save, and confirm redirect.
    choose(new_check_field)
    select(new_license_label, :from => "license_option_#{new_license_option}")
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    # Visit view page, and confirm that changes occured.
    visit polymorphic_path(@hc)
#    find("div.collection-settings").should have_content(new_license)
  end

  it "can edit APO embargo content" do
    # Setup and login.
    orig_embargo        = @hc.embargo         # original value = 1 year, will set to 3 years
    orig_embargo_option = @hc.embargo_option  # original value = varies, will set to fixed
    orig_check_field    = "hydrus_collection_embargo_option_#{orig_embargo_option}"
    new_embargo         = '3 years'
    new_embargo_option  = 'fixed'
    new_check_field     = "hydrus_collection_embargo_option_#{new_embargo_option}"
    no_embargo_option   = 'none'
    no_embargo          = ''
    no_embargo_check_field    = "hydrus_collection_embargo_option_#{no_embargo_option}"
    login_as_archivist1
    # Visit edit page, and confirm content.
    should_visit_edit_page(@hc)
    page.should have_checked_field(orig_check_field)
    page.has_select?('embargo_option_varies').should == true
    page.has_select?('embargo_option_varies', :selected => "#{orig_embargo} after deposit").should == true
    page.has_select?('embargo_option_fixed', :selected => nil).should == true
    # Make changes, save, and confirm redirect.
    choose(new_check_field)
    select(new_embargo, :from => "embargo_option_#{new_embargo_option}")
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    # Visit view-page, and confirm that changes occured.
    visit polymorphic_path(@hc)
 #   find("div.collection-settings").should have_content(new_embargo)
    # Undo changes, and confirm.
    should_visit_edit_page(@hc)
    page.has_select?('embargo_option_varies', :selected => nil).should == true
    page.has_select?('embargo_option_fixed', :selected => "#{new_embargo} after deposit").should == true
    choose(orig_check_field)
    select(orig_embargo, :from => "embargo_option_#{orig_embargo_option}")
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
#    find("div.collection-settings").should have_content(orig_embargo)
    # Set to no embargo after embargo was previously set and ensure there is no longer an embargo period set.
    should_visit_edit_page(@hc)
    page.has_select?('embargo_option_varies', :selected => "#{orig_embargo} after deposit").should == true
    choose(no_embargo_check_field)
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    find("div.collection-settings").should_not have_content(orig_embargo)
    # verify embargo is now 'none'
    @hc.embargo == 'none'
  end

  context "modifying persons and roles" do

    def check_role_management_div(role_info)
      # Takes a role info hash, like that returned by apo_person_roles().
      # Confirms that the role-management section of the current page
      # contains same information.
      rmdiv = find('div#role-management')
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
      login_as_archivist1
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
      rmdiv = find('div#role-management')
      dk    = 'hydrus_collection_apo_person_roles'
      role_info.each do |role,ids|
        rmdiv.fill_in("#{dk}[#{role}]", :with => ids.to_a.join(', '))
      end
      # Check role-management section after additions.
      click_button "Save"
      should_visit_edit_page(@hc)
      check_role_management_div(role_info)
      # Confirm new content in fedora.
      @hc = Hydrus::Collection.find @druid
      @hc.apo_person_roles.should == role_info
    end

    it "should be able to strip email addresses to leave just sunetIDs from persons with various roles" do
      # Visit edit page.
      login_as_archivist1
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
      rmdiv = find('div#role-management')
      dk    = 'hydrus_collection_apo_person_roles'
      role_info.each do |role,ids|
        rmdiv.fill_in("#{dk}[#{role}]", :with => ids.to_a.join(', '))
      end
      # Check role-management section after additions.
      click_button "Save"
      should_visit_edit_page(@hc)
      check_role_management_div(role_info_stripped)
      # Confirm new content in fedora.
      @hc = Hydrus::Collection.find @druid
      @hc.apo_person_roles.should == role_info_stripped
    end
    
  end

  describe "emails" do
    describe "when publishing" do
      before(:each) do
        @coll = Hydrus::Collection.new
      end
      describe "on open" do
        it "should send an email when there are item depositors" do
          login_as_archivist1
          @coll.apo_person_roles = {:"hydrus-collection-item-depositor" => "jdoe"}
          expect {@coll.publish(true)}.to change { ActionMailer::Base.deliveries.count }.by(1)
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent.to.should == ["jdoe@stanford.edu"]
          last_email_sent.subject.should == "Collection opened for deposit in the Stanford Digital Repository"
        end
        it "should not send an email when there are no item depositors" do
          login_as_archivist1
          expect {@coll.publish(true)}.to change { ActionMailer::Base.deliveries.count }.by(0)
        end
      end
      describe "on close" do
        it "should send an email when there are item depositors" do
          login_as_archivist1
          @coll.apo_person_roles = {:"hydrus-collection-item-depositor" => "jdoe"}
          expect {@coll.publish(false)}.to change { ActionMailer::Base.deliveries.count }.by(1)
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent.to.should == ["jdoe@stanford.edu"]
          last_email_sent.subject.should == "Collection closed for deposit in the Stanford Digital Repository"
        end
        it "should not send an email when there are no item depositors" do
          login_as_archivist1
          expect {@coll.publish(false)}.to change { ActionMailer::Base.deliveries.count }.by(0)
        end
      end      
    end
    
    describe "when updating a collection" do
      before(:each) do
        @prev_mint_ids = config_mint_ids()
      end
      after(:each) do
        config_mint_ids(@prev_mint_ids)
      end
      it "should send an email to new depositors when we're updating a collection" do
        login_as_archivist1
        visit new_hydrus_collection_path()
        fill_in "hydrus_collection_title", :with => "TestingTitle"
        fill_in "hydrus_collection_abstract", :with => "Summary of my content"
        fill_in "hydrus_collection_contact", :with => "jdoe@example.com"
        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jdoe"
        click_button("Save")
        page.should have_content("Your changes have been saved.")
        
        expect {click_button("Open Collection")}.to change { ActionMailer::Base.deliveries.count }.by(1)
        
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.to.should == ["jdoe@stanford.edu","archivist1@stanford.edu"]
        last_email_sent.subject.should == "Collection opened for deposit in the Stanford Digital Repository"
      end
      it "should handle complex changes to depositors" do
        login_as_archivist1
        visit new_hydrus_collection_path()
        fill_in "hydrus_collection_title", :with => "TestingTitle"
        fill_in "hydrus_collection_abstract", :with => "Summary of my content"
        fill_in "hydrus_collection_contact", :with => "jdoe@example.com"
        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jdoe, leland, janedoe"
        click_button("Save")
        page.should have_content("Your changes have been saved.")
        click_button("Open Collection")
        click_link("Edit Collection")
        
        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jandoe, leland, jondoe"
        expect {click_button("Save")}.to change { ActionMailer::Base.deliveries.count }.by(1)
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.to.should == ["jandoe@stanford.edu", "jondoe@stanford.edu"]
        last_email_sent.subject.should == "Invitation to deposit in the Stanford Digital Repository"
      end
      it "should not send an email if the collection is closed" do
        login_as_archivist1
        visit new_hydrus_collection_path()
        fill_in "hydrus_collection_apo_person_roles[hydrus-collection-item-depositor]", :with => "jdoe"
        expect {click_button("Save")}.to change { ActionMailer::Base.deliveries.count }.by(0)
      end
    end
  end

end
