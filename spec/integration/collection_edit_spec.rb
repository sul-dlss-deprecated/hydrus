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
    orig_abstract = @hc.abstract.strip
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
    orig_license        = @hc.license         # cc-by  >  odc-odbl
    orig_license_option = @hc.license_option  # fixed  >  varies
    orig_check_field    = "hydrus_collection_license_option_#{orig_license_option}"
    new_license         = 'odc-odbl'
    new_license_option  = 'varies'
    new_check_field     = "hydrus_collection_license_option_#{new_license_option}"
    login_as_archivist1
    # Visit edit page, and confirm content.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    page.should have_checked_field(orig_check_field)
    page.should     have_xpath("//input[@value='#{orig_license}']")
    page.should_not have_xpath("//input[@value='#{new_license}']")
    # Make changes, save, and confirm redirect.
    choose(new_check_field)
    fill_in("hydrus_collection_license", :with => new_license)
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    # Visit view-page, and confirm that changes occured.
    visit polymorphic_path(@hc)
    find("div.collection-settings").should have_content(new_license)
    # Undo changes, and confirm.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    choose(orig_check_field)
    fill_in("hydrus_collection_license", :with => orig_license)
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    find("div.collection-settings").should have_content(orig_license)
  end

  it "can edit APO embargo content" do
    # Setup and login.
    orig_embargo        = @hc.embargo         # 1 year > 3 years
    orig_embargo_option = @hc.embargo_option  # varies > fixed
    orig_check_field    = "hydrus_collection_embargo_option_#{orig_embargo_option}"
    new_embargo         = '3 years'
    new_embargo_option  = 'varies'
    new_check_field     = "hydrus_collection_embargo_option_#{new_embargo_option}"
    login_as_archivist1
    # Visit edit page, and confirm content.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    page.should have_checked_field(orig_check_field)
    #page.has_select?('embargo', :selected => orig_embargo).should == true
    page.should     have_xpath("//input[@value='#{orig_embargo}']")
    page.should_not have_xpath("//input[@value='#{new_embargo}']")
    # Make changes, save, and confirm redirect.
    choose(new_check_field)
    fill_in("hydrus_collection_embargo", :with => new_embargo)
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    # Visit view-page, and confirm that changes occured.
    visit polymorphic_path(@hc)
    find("div.collection-settings").should have_content(new_embargo)
    # Undo changes, and confirm.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    choose(orig_check_field)
    fill_in("hydrus_collection_embargo", :with => orig_embargo)
    click_button "Save"
    current_path.should == polymorphic_path(@hc)
    find("div.collection-settings").should have_content(orig_embargo)
  end
  
end
