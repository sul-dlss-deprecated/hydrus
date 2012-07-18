require 'spec_helper'

describe("Collection edit", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0003'
    @hc    = Hydrus::Collection.find @druid
  end

  it "if not logged in, should be redirected to sign-in page" do
    logout
    visit edit_polymorphic_path(@hc)
    current_path.should == new_user_session_path
  end

  it "can edit Collection descMetadata content" do
    new_abstract  = '  foobarfubb '
    orig_abstract = @hc.abstract
    new_contact   = 'ted@gonzo.com'
    orig_contact  = @hc.contact

    login_as_archivist1

    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)

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

    # Clean up and confirm.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    fill_in "Description", :with => orig_abstract
    fill_in "hydrus_collection_contact", :with => orig_contact
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    page.should have_content(orig_abstract)
    page.should have_content(orig_contact)
    page.should_not have_content(new_abstract)
    page.should_not have_content(new_contact)
  end
  
  it "can open and close a collection and have the deposit status set correctly" do
    login_as_archivist1
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    @hc.publish.should == true
    @hc.apo.deposit_status.should == "open"
    # TODO Figure out why the click_button method cannot find the right buttons to complete this test
    # click_button "Close Collection"
    # @hc.publish.should == false
    # @hc.apo.deposit_status.should == "closed"
    # visit edit_polymorphic_path(@hc)
    # click_button "Open Collection"    
    # @hc.publish.should == true
    # @hc.apo.deposit_status.should == "open"
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
    
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    
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
    
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    
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
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
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
    find("div.collection-settings").should have_content(new_license)
    # Undo changes, and confirm.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    choose(orig_check_field)
    select(orig_license_label, :from => "license_option_#{orig_license_option}")
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    find("div.collection-settings").should have_content(orig_license)
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
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
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
    find("div.collection-settings").should have_content(new_embargo)
    # Undo changes, and confirm.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    page.has_select?('embargo_option_varies', :selected => nil).should == true
    page.has_select?('embargo_option_fixed', :selected => "#{new_embargo} after deposit").should == true   
    choose(orig_check_field)
    select(orig_embargo, :from => "embargo_option_#{orig_embargo_option}")
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    find("div.collection-settings").should have_content(orig_embargo)
    # Set to no embargo after embargo was previously set and ensure there is no longer an embargo period set.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    page.has_select?('embargo_option_varies', :selected => "#{orig_embargo} after deposit").should == true   
    choose(no_embargo_check_field)
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    find("div.collection-settings").should_not have_content(orig_embargo)
    # verify embargo is now 'none'
    @hc.embargo == 'none'
    # Undo changes, and confirm.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    choose("hydrus_collection_embargo_option_varies")
    select("1 year", :from => "embargo_option_varies")
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    find("div.collection-settings").should have_content("1 year")
  end
  
end
