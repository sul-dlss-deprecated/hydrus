require 'spec_helper'

describe("Item edit", :type => :request, :integration => true) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
    @ok_notice = "Your changes have been saved."
    @buttons = {
      :add                 => 'Add',
      :save                => 'save_nojs',
      :add_contributor     => 'Add Contributor',
      :submit_for_approval => 'Submit for Approval',
      :resubmit            => 'Resubmit for Approval',
      :disapprove          => 'Return',
      :approve             => 'Approve and Publish',
      :publish_directly    => 'Publish',
      :open_new_version    => 'Open new version',
    }
  end

  it "If not logged in, should be redirected to the login page, then back to our intended page after logging in" do
    logout
    visit edit_polymorphic_path(@hi)
    current_path.should == new_user_session_path
    fill_in "Email", :with => 'archivist1@example.com'
    fill_in "Password", :with => login_pw
    click_button "Sign in"
    current_path.should == edit_polymorphic_path(@hi)
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
    login_as('archivist1')
    should_visit_edit_page(@hi)
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
    click_button(@buttons[:save])
    # Confirm new location and flash message.
    current_path.should == polymorphic_path(@hi)
    page.should have_content(@ok_notice)
    # Confirm new content in fedora.
    @hi = Hydrus::Item.find @druid
    @hi.abstract.should == ni.abstract
    @hi.contact.should  == ni.contact
    @hi.keywords.should == ni.keywords
  end

  describe "contributors" do

    before(:each) do
      @css = {
        :name     => lambda { |i| "hydrus_item_contributors_#{i}_name" },
        :role     => lambda { |i| "hydrus_item_contributors_#{i}_role_key" },
        :remove   => lambda { |i| "remove_name_#{i}" },
        :view_div => 'div.contributors-list',
      }
    end

    it "scenario with deletes, edits, and adds" do
      # We should have 5 contributors.
      exp = @hi.contributors.map { |c| c.clone }
      exp.size.should == 5
      # Go to edit page.
      login_as('archivist1')
      should_visit_edit_page(@hi)
      # Delete some contributors.
      # Note: [3,1,1] corresponds to elements 3, 1, 2 from original list.
      [3,1,1].each do |i|
        exp.delete_at(i)
        click_link(@css[:remove].call(i))
      end
      # Edit a contributor name.
      nm = 'Herr Finkelstein'
      fill_in(@css[:name].call(0), :with => nm)
      exp[0].name = nm
      # Add some contributors.
      new_contributors = [
        [ 'Foo Conference',  'conference', 'Conference' ],
        [ 'Bar Corp Author', 'corporate',  'Author' ],
        [ 'Quux Author',     'personal',   'Author' ],
      ]
      new_contributors.each do |name, name_type, role|
        # Add a new contributor to exp list.
        c = Hydrus::Contributor.new(
          :name      => name,
          :role      => role,
          :name_type => name_type
        )
        exp << c
        i = exp.size - 1
        # Add the same contributor via the UI.
        q1 = 'select#' + @css[:role].call(i)
        q2 = "option[value='#{c.role_key}']"
        click_button(@buttons[:add_contributor])
        fill_in(@css[:name].call(i), :with => name)
        find(q1).find(q2).select_option
      end
      # Save.
      click_button(@buttons[:save])
      # Check view page.
      vdiv  = find(@css[:view_div])
      roles = vdiv.all('dt').map { |nd| nd.text }
      names = vdiv.all('dd').map { |nd| nd.text }
      roles.zip(names).should == exp.map { |c| [c.role, c.name] }
      # Check Fedora objects.
      @hi = Hydrus::Item.find(@hi.pid)
      @hi.contributors.should == exp
      # Check edit page.
      should_visit_edit_page(@hi)
      exp.each_with_index do |c, i|
        q1 = 'select#' + @css[:role].call(i)
        q2 = 'input#'  + @css[:name].call(i)
        find(q1).value.should == c.role_key
        find(q2).value.should == c.name
      end
    end

  end

  it "Related Content editing with adding protocol if it is missing" do
    orig_link   = @hi.descMetadata.relatedItem.location.url.first
    new_link    = "foo_LINK_bar"
    field_link  = "hydrus_item_related_item_url_0"
    orig_title  = @hi.descMetadata.relatedItem.titleInfo.title.first
    new_title   = "foo_TITLE_bar"
    field_title = "hydrus_item_related_item_title_0"

    login_as('archivist1')
    should_visit_edit_page(@hi)

    find_field(field_link).value.should == orig_link
    find_field(field_title).value.should == orig_title

    fill_in(field_link,  :with => new_link)
    fill_in(field_title, :with => new_title)
    click_button(@buttons[:save])
    page.should have_content(@ok_notice)

    # Confirm new content in fedora.
    @hi = Hydrus::Item.find(@druid)
    @hi.descMetadata.relatedItem.titleInfo.title.first.should == new_title
    @hi.descMetadata.relatedItem.location.url.first == "http://#{new_link}"
  end

  it "Related Content editing" do
    orig_link   = @hi.descMetadata.relatedItem.location.url.first
    new_link    = "https://foo_LINK_bar"
    field_link  = "hydrus_item_related_item_url_0"
    orig_title  = @hi.descMetadata.relatedItem.titleInfo.title.first
    new_title   = "foo_TITLE_bar"
    field_title = "hydrus_item_related_item_title_0"

    login_as('archivist1')
    should_visit_edit_page(@hi)

    find_field(field_link).value.should == orig_link
    find_field(field_title).value.should == orig_title

    fill_in(field_link,  :with => new_link)
    fill_in(field_title, :with => new_title)
    click_button(@buttons[:save])
    page.should have_content(@ok_notice)

    # Confirm new content in fedora.
    @hi = Hydrus::Item.find(@druid)
    @hi.descMetadata.relatedItem.titleInfo.title.first.should == new_title
    @hi.descMetadata.relatedItem.location.url.first == new_link
  end


  it "Related Content adding and deleting" do
    i             = @hi.related_item_title.size
    css_new_title = "hydrus_item_related_item_title_#{i}"
    css_new_url   = "hydrus_item_related_item_url_#{i}"
    css_delete    = "remove_relatedItem_#{i}"
    url           = "http://library.stanford.edu"
    title         = "Library Website"
    # Got to edit page.
    login_as('archivist1')
    should_visit_edit_page(@hi)
    # Check for the related item input fields.
    (0...i).each do |j|
      page.should have_css("input#hydrus_item_related_item_title_#{j}")
      page.should have_css("input#hydrus_item_related_item_url_#{j}")
      page.should have_css("#remove_relatedItem_#{j}")
    end
    page.should_not have_css("##{css_new_title}")
    page.should_not have_css("##{css_new_url}")
    page.should_not have_css("##{css_delete}")
    # Add a new related item
    click_button "add_link"
    page.should have_css("##{css_new_title}")
    page.should have_css("##{css_new_url}")
    page.should have_css("##{css_delete}")
    fill_in(css_new_title, :with => title)
    fill_in(css_new_url, :with => url)
    # Save.
    click_button(@buttons[:save])
    page.should have_content(@ok_notice)
    # Make sure the descMetadata has the expected N of relatedItem nodes.
    # At one point we had a bug where the new title and url were added
    # to the first node rather than the new empty node.
    @hi = Hydrus::Item.find(@hi.pid)
    @hi.descMetadata.find_by_terms(:relatedItem).size.should == i + 1
    # Revisit edit page and check for the values we just added.
    should_visit_edit_page(@hi)
    page.should have_css("##{css_delete}")
    find_field(css_new_title).value.should == title
    find_field(css_new_url).value.should == url
    # Delete the item we added.
    click_link css_delete
    current_path.should == edit_polymorphic_path(@hi)
    page.should_not have_css("##{css_new_title}")
    page.should_not have_css("##{css_new_url}")
    page.should_not have_css("##{css_delete}")
  end

  it "editing related content w/o titles" do
    # Save copy of the original datastreams.
    @druid = "druid:oo000oo0005"
    @hi    = Hydrus::Item.find(@druid)
    # Set up the new values for the fields we will edit.
    ni = hash2struct(
      :ri_title => 'My URL title',
      :ri_url   => 'http://stanford.and.son',
      :title_f  => "hydrus_item_related_item_title_0",
      :url_f    => "hydrus_item_related_item_url_0",
    )
    # Visit edit page.
    login_as('archivist1')
    should_visit_edit_page(@hi)
    # Make sure the object does not have the new content yet.
    old_title = find_field(ni.title_f).value
    old_url = find_field(ni.url_f).value
    old_title.should be_blank
    old_url.should_not == ni.ri_url
    # Submit some changes.
    fill_in ni.title_f, :with => ni.ri_title
    fill_in ni.url_f, :with => ni.ri_url
    click_button(@buttons[:save])
    # Confirm new location and flash message.
    current_path.should == polymorphic_path(@hi)
    page.should have_content(@ok_notice)
    # Confirm new content in fedora.
    @hi = Hydrus::Item.find(@druid)
    @hi.related_item_title.first.should == ni.ri_title
  end

  it "can edit preferred citation field" do
    citation_field = "hydrus_item_preferred_citation"
    new_pref_cit  = "new_citation_FOO"
    orig_pref_cit = @hi.preferred_citation

    login_as('archivist1')
    should_visit_edit_page(@hi)

    find_field(citation_field).value.strip.should == orig_pref_cit
    fill_in citation_field, :with => new_pref_cit
    click_button(@buttons[:save])
    page.should have_content(@ok_notice)

    # Confirm new content in fedora.
    @hi = Hydrus::Item.find(@druid)
    @hi.preferred_citation == new_pref_cit
  end

  it "Related citation adding and deleting" do

    new_citation         = "hydrus_item_related_citation_2"
    new_delete_button    = "remove_related_citation_2"
    new_citation_text    = " This is a citation for a related item! "

    login_as('archivist1')
    should_visit_edit_page(@hi)

    page.should have_css("textarea#hydrus_item_related_citation_0")
    page.should have_css("textarea#hydrus_item_related_citation_1")

    page.should_not have_css("textarea##{new_citation}")
    page.should_not have_css("##{new_delete_button}")

    click_button "add_related_citation"
    current_path.should == edit_polymorphic_path(@hi)

    page.should have_css("##{new_citation}")
    page.should have_css("##{new_delete_button}")

    fill_in(new_citation, :with => new_citation_text)

    click_button(@buttons[:save])
    page.should have_content(@ok_notice)

    should_visit_edit_page(@hi)

    page.should have_css("##{new_delete_button}")
    find_field(new_citation).value.strip.should == new_citation_text.strip

    # delete
    click_link new_delete_button

    current_path.should == edit_polymorphic_path(@hi)
    page.should_not have_css("##{new_citation}")
    page.should_not have_css("##{new_delete_button}")
  end

  it "should have editible license information once the parent collection's license is set to varies" do
    varies_radio           = "hydrus_collection_license_option_varies"
    collection_licenses    = "license_option_varies"
    new_collection_license = "CC BY Attribution"
    item_licenses          = "hydrus_item_license"
    new_item_license       = "PDDL Public Domain Dedication and License"
    no_license             = "No license"
    css_lic_select         = "optgroup/option[@selected='selected']"

    # Item has expected rights.
    ps = {:embargo_date=>'', :visibility=>'world', :license_code=>'cc-by'}
    check_emb_vis_lic(@hi,ps)

    # Modify the collection to allow varying license.
    login_as('archivist1')
    should_visit_edit_page(Hydrus::Collection.find("druid:oo000oo0003"))
    choose varies_radio
    select(new_collection_license, :from => collection_licenses)
    click_button(@buttons[:save])
    page.should have_content(@ok_notice)

    # Item edit page should offer ability to select a license.
    should_visit_edit_page(@hi)
    page.should have_selector("##{item_licenses}")

    # Verify that the default license set at the collection-level is selected.
    within("select##{item_licenses}") do
      selected_license = find(css_lic_select).text
      selected_license.should == new_collection_license
    end

    # Select a different license, and save.
    select(new_item_license, :from => item_licenses)
    click_button(@buttons[:save])
    page.should have_content(@ok_notice)

    # Item has expected rights.
    @hi = Hydrus::Item.find @druid
    ps = {:embargo_date => '', :visibility => 'world', :license_code => 'pddl'}
    check_emb_vis_lic(@hi,ps)

    # Back to the edit page.
    should_visit_edit_page(@hi)

    # Verify that the previous license was set.
    within("select##{item_licenses}") do
      selected_license = find(css_lic_select).text
      selected_license.should == new_item_license
    end

    # Select no license, and save.
    select(no_license, :from => item_licenses)
    click_button(@buttons[:save])
    page.should have_content(@ok_notice)

    # Back to the edit page.
    should_visit_edit_page(@hi)

    # Verify that the previous license was set.
    within("select##{item_licenses}") do
      selected_license = find(css_lic_select).text
      selected_license.should == no_license
    end

    # Select original license, and save.
    select(new_collection_license, :from => item_licenses)
    click_button(@buttons[:save])
    page.should have_content(@ok_notice)

    # Back to the edit page.
    should_visit_edit_page(@hi)

    # Verify that the previous license was set.
    within("select##{item_licenses}") do
      selected_license = find(css_lic_select).text
      selected_license.should == new_collection_license
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

      # Create an item.
      owner    = 'archivist1'
      reviewer = 'archivist5'
      viewer   = 'archivist7'
      hi = create_new_item()

      # Submit for approval.
      # A viewer should not see the button.
      b = @buttons[:submit_for_approval]
      login_as(viewer)
      should_visit_view_page(hi)
      page.should_not have_button(b)

      # But the owner should see the button.
      # Submit it for approval.
      login_as(owner)
      should_visit_view_page(hi)
      click_button(b)

      # Disapprove item.
      # A viewer should not see the button.
      b = @buttons[:disapprove]
      login_as(viewer)
      should_visit_view_page(hi)
      page.should_not have_button(b)

      # But the reviewer should see the button.
      # Disapprove the item.
      login_as(reviewer)
      should_visit_view_page(hi)
      fill_in "hydrus_item_disapproval_reason", :with => "Doh!"
      click_button(b)

      # Resubmit item.
      # A viewer should not see the button.
      b = @buttons[:resubmit]
      login_as(viewer)
      should_visit_view_page(hi)
      page.should_not have_button(b)

      # But the owner should see the button.
      # Resubmit the item.
      login_as(owner)
      should_visit_view_page(hi)
      click_button(b)

      # Approve item.
      # A viewer should not see the button.
      b = @buttons[:approve]
      login_as(viewer)
      should_visit_view_page(hi)
      page.should_not have_button(b)

      # But the reviewer should see the button.
      # Disapprove the item.
      login_as(reviewer)
      should_visit_view_page(hi)
      click_button(b)

      # Create another item, one not requiring review.
      hi = create_new_item(:requires_human_approval => 'no')

      # Publish directly.
      # A viewer should not see the button.
      b = @buttons[:publish_directly]
      login_as(viewer)
      should_visit_view_page(hi)
      page.should_not have_button(b)

      # But the owner should see the button.
      # Publish directly.
      login_as(owner)
      should_visit_view_page(hi)
      click_button(b)

    end

  end

  describe "embargo and visibility" do

    it "setting/removing embargo date modifies embargoMD and rightsMD as expected" do
      css = {
        :emb_yes  => 'hydrus_item_embarg_visib_embargoed_yes',
        :emb_no   => 'hydrus_item_embarg_visib_embargoed_no',
        :visib    => 'hydrus_item_embarg_visib_visibility',
        :emb_date => 'hydrus_item_embarg_visib_date',
      }
      lic = 'cc-by'

      # Change collection to allow for variable visibility for its items.
      hc = @hi.collection
      hc.visibility_option_value = 'varies'
      hc.save

      # Reset the Item's publish time, so this test won't fail a year from now.
      today    = HyTime.now.beginning_of_day
      later    = today + 10.days
      later_dt = HyTime.datetime(later, :from_localzone => true)
      later_d  = HyTime.date(later, :from_localzone => true)
      @hi.initial_submitted_for_publish_time = HyTime.datetime(today, :from_localzone => true)
      @hi.save

      # Check embargoMD and rightsMD: initial.
      check_emb_vis_lic(@hi,
        :embargo_date => '',
        :visibility   => 'world',
        :license_code => lic,
      )

      # Login.
      login_as('archivist1')

      # Visit edit page: set an embargo date and change visibility.
      should_visit_edit_page(@hi)
      choose(css[:emb_yes])
      fill_in(css[:emb_date], :with => later_d)
      select('Stanford only', :from => css[:visib])

      # Save and confirm.
      click_button(@buttons[:save])
      current_path.should == polymorphic_path(@hi)
      page.should have_content(@ok_notice)

      # Check embargoMD and rightsMD: after setting an embargo date.
      @hi = Hydrus::Item.find(@hi.pid)
      check_emb_vis_lic(@hi,
        :embargo_date => later_dt,
        :visibility   => 'stanford',
        :license_code => lic,
      )

      # Visit edit page: remove embargo.
      should_visit_edit_page(@hi)
      choose(css[:emb_no])

      # Save and confirm.
      click_button(@buttons[:save])
      current_path.should == polymorphic_path(@hi)
      page.should have_content(@ok_notice)

      # Check embargoMD and rightsMD: after removing embargo.
      @hi = Hydrus::Item.find(@hi.pid)
      check_emb_vis_lic(@hi,
        :embargo_date => '',
        :visibility   => 'stanford',
        :license_code => lic,
      )
    end

  end

  describe "uploaded files" do

    it "hide indicator on view page" do
      # Setup:
      #   - Object has 4 uploaded files, with IDs 1 - 4.
      #   - Files with odd IDs will be hidden.
      #   - Store a hash with IDs and keys and FILE_INFO hashes as values.
      exp = {}
      @hi.files.each do |f|
        lab = "label_#{f.id}"
        hid = (f.id % 2 == 1)
        f.label = lab
        f.hide  = hid
        f.save
        exp[f.id] = f.get_file_info
      end

      # A lambda we will use to check:
      #   - the display of file labels and hide status on the Item view page.
      #   - the corresponding values from the ObjectFile itself.
      #   - the N of ObjectFiles for the Item.
      check_file_info = lambda { |exp_hash|
        span = 'div.item-files td span'
        exp_hash.each do |id, fi|
          # Check view page.
          lab = fi[:label]
          hid = fi[:hide]
          find("#{span}.file_label_#{id}").should have_content(lab)
          txt = find("#{span}.hide_status_#{id}").text
          txt.include?('[hidden]').should == hid
          # Check ObjectFile.
          hof = Hydrus::ObjectFile.find(id)
          hof.get_file_info.should == fi
        end
        # Check total N of ObjectFiles.
        Hydrus::ObjectFile.find_all_by_pid(@hi.pid).size.should == exp.keys.size
      }

      # Login.
      login_as('archivist1')

      # Visit view page and check file info.
      should_visit_view_page(@hi)
      check_file_info.call(exp)

      # Visit edit page: modify labels, and change hide settings.
      # Files with IDs 1 and 2 will be hidden.
      should_visit_edit_page(@hi)
      exp.each do |id, fi|
        # Confirm that form has expected values.
        css_lab = "file_info_#{id}_label"
        css_hid = "file_info_#{id}_hide"
        find_by_id(css_lab).value.should    == fi[:label]
        find_by_id(css_hid).checked?.should == (fi[:hide] ? 'checked' : nil)
        # Modify the values -- in the exp hash.
        lab = 'foo_' + fi[:label]
        hid = (id < 3)
        exp[id][:label] = lab
        exp[id][:hide]  = hid
        # Modify the values -- in the web form.
        fill_in(css_lab, :with => lab)
        meth = hid ? :check : :uncheck
        send(meth, css_hid)
      end
      click_button(@buttons[:save])

      # Visit view page and check file info.
      should_visit_view_page(@hi)
      check_file_info.call(exp)

      # Visit edit page: delete a file.
      # Make corresponding changes in the exp hash.
      i = 1
      file_url = Hydrus::ObjectFile.find(i).url
      should_visit_edit_page(@hi)
      css_del = "delete_file_#{i}"
      click_link(css_del)
      exp.delete(i)

      # After delete we are still on edit page.
      # It should not have the deleted file.
      page.has_link?(css_del).should == false

      # Visit view page and check file info.
      should_visit_view_page(@hi)
      check_file_info.call(exp)

      # Restore the deleted file.
      restore_upload_file(file_url)
      File.exists?('public' + file_url).should == true
    end

  end

end
