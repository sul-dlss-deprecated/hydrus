require 'spec_helper'

describe("Item edit", :type => :request, :integration => true) do
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

  it "should be able to edit simple items: abstract, contact, keywords" do
    # Set up the new values for the fields we will edit.
    ni = hash2struct(
      :abstract => 'abcxyz123',
      :contact  => 'ozzy@hell.com',
      :keywords => %w(foo bar fubb),
    )
    comma_join  = '  ,  '
    # Visit edit page.
    login_as_archivist1
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    # Make sure the object does not have the new content yet.
    @hi.abstract.should_not == ni.abstract
    @hi.contact.should_not  == ni.contact
    @hi.keywords.should_not == ni.keywords
    find_field("Abstract").value.should_not include(ni.abstract)
    find_field("hydrus_item_contact").value.should_not include(ni.contact)
    find_field("Keywords").value.should_not include(ni.keywords[0])
    # Submit some changes.
    fill_in("Abstract", :with => "  #{ni.abstract}  ")
    fill_in("hydrus_item_contact", :with => "  #{ni.contact}  ")
    fill_in("Keywords", :with => "  #{ni.keywords.join(comma_join)}  ")
    click_button "Save"
    # Confirm new location and flash message.
    current_path.should == polymorphic_path(@hi)
    page.should have_content(@notice)
    # Confirm new content in fedora.
    @hi = Hydrus::Item.find @druid
    @hi.abstract.should == ni.abstract
    @hi.contact.should  == ni.contact
    @hi.keywords.should == ni.keywords
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
    # Save copy of the original datastreams.
    @druid       = "druid:oo000oo0005"
    @hi          = Hydrus::Item.find(@druid)
    orig_content = get_original_content(@hi, 'descMetadata')
    # Set up the new values for the fields we will edit.
    ni = hash2struct(
      :ri_title => 'My URL title',
      :ri_url   => 'http://stanford.and.son',
      :title_f  => "hydrus_item_related_item_title_0",
      :url_f    => "hydrus_item_related_item_url_0",
    )
    # Visit edit page.
    login_as_archivist1
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    # Make sure the object does not have the new content yet.
    old_title = find_field(ni.title_f).value
    old_url = find_field(ni.url_f).value
    old_title.should be_blank
    old_url.should_not == ni.ri_url
    # Submit some changes.
    fill_in ni.title_f, :with => ni.ri_title
    fill_in ni.url_f, :with => ni.ri_url
    click_button "Save"
    # Confirm new location and flash message.
    current_path.should == polymorphic_path(@hi)
    page.should have_content(@notice)
    # Confirm new content on page and in fedora.
    find("dd a[href='#{ni.ri_url}']").should have_content ni.ri_title
    @hi = Hydrus::Item.find(@druid)
    @hi.related_item_title.first.should == ni.ri_title
    # Restore the original datastreams.
    restore_original_content(@hi, orig_content)
  end

  it "can edit preferred citation field" do
    citation_field = "hydrus_item_preferred_citation"
    new_pref_cit  = "new_citation_FOO"
    orig_pref_cit = @hi.preferred_citation
    
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
  end
  
  it "Related citation adding and deleting" do
    
    new_citation         = "hydrus_item_related_citation_2" 
    new_delete_button    = "remove_related_citation_2"
    new_citation_text    = " This is a citation for a related item! "
    
    login_as_archivist1
    
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    
    page.should have_css("textarea#hydrus_item_related_citation_0")
    page.should have_css("textarea#hydrus_item_related_citation_1")
    
    page.should_not have_css("textarea##{new_citation}")
    page.should_not have_css("##{new_delete_button}")
    
    click_button "add_related_citation"
    current_path.should == edit_polymorphic_path(@hi)
    
    page.should have_css("##{new_citation}")
    page.should have_css("##{new_delete_button}")
    
    fill_in(new_citation, :with => new_citation_text)
    
    click_button "Save"
    page.should have_content(@notice)
    
    visit edit_polymorphic_path(@hi)
    current_path.should == edit_polymorphic_path(@hi)
    
    page.should have_css("##{new_delete_button}")
    find_field(new_citation).value.strip.should == new_citation_text.strip
    
    # delete
    click_link new_delete_button
    
    current_path.should == edit_polymorphic_path(@hi)
    page.should_not have_css("##{new_citation}")
    page.should_not have_css("##{new_delete_button}")
  end

end

