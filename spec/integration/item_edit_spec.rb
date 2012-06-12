require 'spec_helper'

describe("Item edit", :type => :request) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
    @notice = "Your changes have been saved."
  end

  it "If not logged in, should be redirected to sign-in page" do
    logout
    visit edit_polymorphic_path(@hi)
    current_path.should == new_user_session_path
  end

  it "Can edit basic content" do
    new_name  = 'abcxyz123'
    orig_name = @hi.descMetadata.abstract.first.strip

    login_as_archivist1

    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)

    find_field("Abstract").value.strip.should == orig_name
    fill_in "Abstract", :with => new_name
    click_button "Save"
    page.should have_content(@notice)

    current_path.should == polymorphic_path(@hi)
    visit polymorphic_path(@hi)
    page.should have_content(new_name)

    # Clean up.
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    fill_in "Abstract", :with => orig_name
    click_button "Save"
  end
  
  it "People/Role editing" do
    new_name  = "MY EDITIED PERSON"
    orig_name = "Rosenfeld, Michael J."
    field_np  = "hydrus_item_person_0"
    field_rt  = "hydrus_item_person_role_0"
    orig_role = "Principal Investigator"
    new_role  = "Collector"

    login_as_archivist1

    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)

    find_field(field_np).value.should == orig_name
    page.should have_content(orig_role)

    fill_in(field_np, :with => new_name)
    select(new_role, :from => field_rt)
    click_button "Save"
    page.should have_content(@notice)

    current_path.should == polymorphic_path(@hi)
    visit polymorphic_path(@hi)
    page.should have_content(new_name)
    page.should have_content(new_role)

    # Clean up.
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    fill_in(field_np, :with => orig_name)
    select(orig_role, :from => field_rt)
    click_button "Save"
  end
  
  it "People/Role adding and deleting" do
    new_field = "hydrus_item_person_5"
    new_delete_button = "remove_name_5"
    person = "Mr. Test Person"
    
    login_as_archivist1
    
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    
    page.should have_css("input#hydrus_item_person_4")
    page.should_not have_css("##{new_field}")
    
    click_button "add_person"
    page.should have_css("##{new_field}")
    page.should have_css("##{new_delete_button}")
    
    fill_in(new_field, :with => person)
    click_button "Save"
    page.should have_content(@notice)
    
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    
    page.should have_css("##{new_delete_button}")
    find_field(new_field).value.should == person
    
    # delete
    click_link new_delete_button
    
    current_path.should == edit_polymorphic_path(@hi)
    page.should_not have_css("##{new_field}")
    page.should_not have_css("##{new_delete_button}")
  end

  it "Related Content editing" do
    orig_link   = @hi.descMetadata.relatedItem.location.url.first
    new_link    = "foo_LINK_bar"
    field_link  = "hydrus_item_related_item_url_0"
    orig_title  = @hi.descMetadata.relatedItem.titleInfo.title.first
    new_title   = "foo_TITLE_bar"
    field_title = "hydrus_item_related_item_title_0"

    login_as_archivist1

    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)

    find_field(field_link).value.should == orig_link
    find_field(field_title).value.should == orig_title

    fill_in(field_link,  :with => new_link)
    fill_in(field_title, :with => new_title)
    click_button "Save"
    page.should have_content(@notice)

    current_path.should == polymorphic_path(@hi)
    visit polymorphic_path(@hi)
    page.should have_xpath("//dd/a[@href='#{new_link}']")
    page.should have_content(new_title)

    # Clean up.
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    fill_in(field_link,  :with => orig_link)
    fill_in(field_title, :with => orig_title)
    click_button "Save"
  end
  
  it "Related Content adding and deleting" do
    new_label         = "hydrus_item_related_item_title_2"
    new_url           = "hydrus_item_related_item_url_2"
    new_delete_button = "remove_relatedItem_2"
    url               = "http://library.stanford.edu"
    label             = "Library Website"
    
    login_as_archivist1
    
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    
    page.should have_css("input#hydrus_item_related_item_title_0")
    page.should have_css("input#hydrus_item_related_item_url_0")
    page.should_not have_css("##{new_label}")
    page.should_not have_css("##{new_url}")
    
    click_button "add_link"
    page.should have_css("##{new_label}")
    page.should have_css("##{new_url}")
    page.should have_css("##{new_delete_button}")
    
    fill_in(new_label, :with => label)
    fill_in(new_url, :with => url)
    
    click_button "Save"
    page.should have_content(@notice)
    
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    
    page.should have_css("##{new_delete_button}")
    find_field(new_label).value.should == label
    find_field(new_url).value.should == url
    
    # delete
    click_link new_delete_button
    
    current_path.should == edit_polymorphic_path(@hi)
    page.should_not have_css("##{new_label}")
    page.should_not have_css("##{new_url}")
    page.should_not have_css("##{new_delete_button}")
  end
  
  it "editing related content w/o titles" do
    object = Hydrus::Item.find("druid:oo000oo0005")
    title_field = "hydrus_item_related_item_title_0"
    url_field = "hydrus_item_related_item_url_0"
    
    login_as_archivist1
    
    visit edit_polymorphic_path(object)
    current_path.should == edit_polymorphic_path(object)
    
    old_title = find_field(title_field).value
    old_url = find_field(url_field).value
    new_title = "My URL Title"
    new_url = "http://library.stanford.edu"
    
old_title.should == ""    
    old_title.should be_blank
    
    fill_in title_field, :with => new_title
    fill_in url_field, :with => new_url
    
    click_button "Save"
    page.should have_content(@notice)
    
    page.should have_content new_title
    
    #cleanup
    visit edit_polymorphic_path(object)
    current_path.should == edit_polymorphic_path(object)
    fill_in title_field, :with => old_title
    fill_in url_field, :with => old_url
    
    click_button "Save"
  end

  it "can edit preferred citation field" do
    citation_field = "hydrus_item_preferred_citation"
    new_pref_cit  = "new_citation_FOO"
    orig_pref_cit = @hi.descMetadata.preferred_citation.first.strip
    
    login_as_archivist1

    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)

    find_field(citation_field).value.strip.should == orig_pref_cit
    fill_in citation_field, :with => new_pref_cit
    click_button "Save"
    page.should have_content(@notice)

    current_path.should == polymorphic_path(@hi)
    visit polymorphic_path(@hi)
    page.should have_content(new_pref_cit)

    # Clean up.
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    fill_in citation_field, :with => orig_pref_cit
    click_button "Save"
  end

end
