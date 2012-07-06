require 'spec_helper'

describe("Collection edit", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0003'
    @hc    = Hydrus::Collection.find @druid
  end

  it "If not logged in, should be redirected to sign-in page" do
    logout
    visit edit_polymorphic_path(@hc)
    current_path.should == new_user_session_path
  end

  it "Can edit some Collection content" do
    new_abstract  = 'foobarfubb'
    orig_abstract = @hc.abstract.first.strip
    new_contact   = 'ted@gonzo.com'
    orig_contact  = @hc.contact.strip

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
    page.should have_content(new_abstract)

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
  
  it "Can edit and delete multi-valued fields" do
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

end
