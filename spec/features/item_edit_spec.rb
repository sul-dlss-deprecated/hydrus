require 'spec_helper'

describe('Item edit', type: :request, integration: true) do
  let(:archivist1) { create :archivist1 }
  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
    @ok_notice = 'Your changes have been saved.'
    @buttons = {
      add: 'Add',
      save: 'save_nojs',
      add_contributor: 'Add Contributor',
      submit_for_approval: 'Submit for Approval',
      resubmit: 'Resubmit for Approval',
      disapprove: 'Return',
      approve: 'Approve and Publish',
      publish_directly: 'Publish',
      open_new_version: 'Open new version',
    }
    sign_in(archivist1)
  end

  context 'without logging in' do
    it 'redirects to login' do
      sign_out
      get edit_polymorphic_path(@hi)
      expect(response.code).to eq('302')
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'when logged in as archivist1' do
    it 'is able to edit simple items: abstract, contact, keywords' do
      # Set up the new values for the fields we will edit.
      ni = OpenStruct.new(
        abstract: 'abcxyz123',
        contact: 'ozzy@hell.com',
        keywords: %w(foo bar fubb),
      )
      comma_join = '  ,  '
      # Visit edit page.
      should_visit_edit_page(@hi)
      # Make sure the object does not have the new content yet.
      expect(@hi.abstract).not_to eq(ni.abstract)
      expect(@hi.contact).not_to  eq(ni.contact)
      expect(@hi.keywords).not_to eq(ni.keywords)
      expect(find_field('Abstract').value).not_to include(ni.abstract)
      expect(find_field('hydrus_item_contact').value).not_to include(ni.contact)
      expect(find_field('Keywords').value).not_to include(ni.keywords[0])
      # Submit some changes.
      fill_in('Abstract', with: "  #{ni.abstract}  ")
      fill_in('hydrus_item_contact', with: "  #{ni.contact}  ")
      fill_in('Keywords', with: "  #{ni.keywords.join(comma_join)}  ")
      click_button(@buttons[:save])
      # Confirm new location and flash message.
      expect(current_path).to eq(polymorphic_path(@hi))
      expect(page).to have_content(@ok_notice)
      # Confirm new content in fedora.
      @hi = Hydrus::Item.find @druid
      expect(@hi.abstract).to eq(ni.abstract)
      expect(@hi.contact).to  eq(ni.contact)
      expect(@hi.keywords).to eq(ni.keywords)
    end
  end

  describe 'dates' do
    it 'should edit a single date' do
      # Visit edit page.
      should_visit_edit_page(@hi)
      date_val = '2004'
      expect(find_field('hydrus_item[dates[date_created]]').value).not_to include(date_val)

      # Submit some changes.
      fill_in('hydrus_item[dates[date_created]]', with: date_val)
      choose('hydrus_item_dates_date_type_single')
      check 'hydrus_item_dates_date_created_approximate'
      click_button(@buttons[:save])
      # Confirm new location and flash message.
      expect(current_path).to eq(polymorphic_path(@hi))
      expect(page).to have_content(@ok_notice)
      # Confirm new content in fedora.
      @hi = Hydrus::Item.find @druid
      expect(@hi.descMetadata.originInfo.dateCreated.nodeset.first.text).to eq(date_val)
      expect(@hi.descMetadata.originInfo.dateCreated.nodeset.first['keyDate']).to eq('yes')
      expect(@hi.descMetadata.originInfo.dateCreated.nodeset.first['encoding']).to eq('w3cdtf')
      expect(@hi.descMetadata.originInfo.dateCreated.nodeset.first['qualifier']).to eq('approximate')

      # check for duplicate nodes hannah reported
      expect(@hi.descMetadata.originInfo.length).to eq(1)
    end
    it 'should edit a date range' do
      # Visit edit page.
      should_visit_edit_page(@hi)
      date_val = '2004'
      date_val_end = '2005'
      expect(find_field('hydrus_item[dates[date_start]]').value).not_to include(date_val)

      # Submit some changes.
      fill_in('hydrus_item[dates[date_start]]', with: date_val)
      check 'hydrus_item_dates_date_range_start_approximate'
      fill_in('hydrus_item[dates[date_range_end]]', with: date_val_end)
      choose('hydrus_item_dates_date_type_range')
      click_button(@buttons[:save])
      # Confirm new location and flash message.
      expect(current_path).to eq(polymorphic_path(@hi))
      expect(page).to have_content(@ok_notice)
      # Confirm new content in fedora.
      @hi = Hydrus::Item.find @druid
      expect(@hi.dates[:date_range_start]).to eq([date_val])
      expect(@hi.descMetadata.originInfo.length).to eq(1)
      expect(@hi.descMetadata.originInfo.date_range_start.nodeset.first['keyDate']).to eq('yes')
      expect(@hi.descMetadata.originInfo.date_range_start.nodeset.first['encoding']).to eq('w3cdtf')
      expect(@hi.descMetadata.originInfo.date_range_start.nodeset.first['qualifier']).to eq('approximate')
      expect(@hi.dates[:date_range_end]).to eq([date_val_end])
      expect(@hi.descMetadata.originInfo.date_range_end.nodeset.first['encoding']).to eq('w3cdtf')
    end
  end

  describe 'contributors' do
    it 'scenario with deletes, edits, and adds' do
      # We should have 5 contributors.
      exp = @hi.contributors.map { |c| c.clone }
      expect(exp.size).to eq(5)
      # Go to edit page.
      should_visit_edit_page(@hi)
      # Delete some contributors.
      # Note: [3,1,1] corresponds to elements 3, 1, 2 from original list.
      click_link('remove_name_3')
      click_link('remove_name_1')
      click_link('remove_name_1')
      # Edit a contributor name.
      fill_in('hydrus_item_contributors_0_name', with: 'Herr Finkelstein')
      # Add some contributors.
      new_contributors = [
        ['Foo Conference',  'conference', 'Conference'],
        ['Bar Corp Author', 'corporate',  'Author'],
        ['Quux Author',     'personal',   'Author'],
      ]
      click_button('Add Contributor')
      select 'Conference', from: 'hydrus_item_contributors_2_role_key'
      fill_in('hydrus_item_contributors_2_name', with: 'Foo Conference')
      click_button('Add Contributor')
      find('select#hydrus_item_contributors_3_role_key').find('option[value="corporate_author"]').select_option
      fill_in('hydrus_item_contributors_3_name', with: 'Bar Corp Author')
      click_button('Add Contributor')
      find('select#hydrus_item_contributors_4_role_key').find('option[value="personal_author"]').select_option
      fill_in('hydrus_item_contributors_4_name', with: 'Quux Author')
      # Save.
      click_button(@buttons[:save])
      # Check view page.
      vdiv  = find('div.contributors-list')
      roles = vdiv.all('dt').map { |nd| nd.text }
      names = vdiv.all('dd').map { |nd| nd.text }
      expect(roles.zip(names)).to eq [
        ['Principal investigator', 'Herr Finkelstein'],
        ['Sponsor', 'UPS endowment at Stanford University'],
        ['Conference', 'Foo Conference'],
        ['Author', 'Bar Corp Author'],
        ['Author', 'Quux Author'],
      ]
      # Check edit page.
      should_visit_edit_page(@hi)
      expect(page).to have_select('hydrus_item_contributors_0_role_key', selected: 'Principal investigator')
      expect(page).to have_select('hydrus_item_contributors_1_role_key', selected: 'Sponsor')
      expect(page).to have_select('hydrus_item_contributors_2_role_key', selected: 'Conference')
      expect(page).to have_select('hydrus_item_contributors_3_role_key', selected: 'Author')
      expect(page).to have_select('hydrus_item_contributors_4_role_key', selected: 'Author')

      expect(page).to have_field('hydrus_item_contributors_0_name', with: 'Herr Finkelstein')
      expect(page).to have_field('hydrus_item_contributors_1_name', with: 'UPS endowment at Stanford University')
      expect(page).to have_field('hydrus_item_contributors_2_name', with: 'Foo Conference')
      expect(page).to have_field('hydrus_item_contributors_3_name', with: 'Bar Corp Author')
      expect(page).to have_field('hydrus_item_contributors_4_name', with: 'Quux Author')
    end
  end

  it 'Related Content editing with adding protocol if it is missing' do
    orig_link   = @hi.descMetadata.relatedItem.location.url.first
    new_link    = 'foo_LINK_bar'
    field_link  = 'hydrus_item_related_item_url_0'
    orig_title  = @hi.descMetadata.relatedItem.titleInfo.title.first
    new_title   = 'foo_TITLE_bar'
    field_title = 'hydrus_item_related_item_title_0'

    should_visit_edit_page(@hi)

    expect(find_field(field_link).value).to eq(orig_link)
    expect(find_field(field_title).value).to eq(orig_title)

    fill_in(field_link,  with: new_link)
    fill_in(field_title, with: new_title)
    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)

    # Confirm new content in fedora.
    @hi = Hydrus::Item.find(@druid)
    expect(@hi.descMetadata.relatedItem.titleInfo.title.first).to eq(new_title)
    @hi.descMetadata.relatedItem.location.url.first == "http://#{new_link}"
  end

  it 'Related Content editing' do
    orig_link   = @hi.descMetadata.relatedItem.location.url.first
    new_link    = 'https://foo_LINK_bar'
    field_link  = 'hydrus_item_related_item_url_0'
    orig_title  = @hi.descMetadata.relatedItem.titleInfo.title.first
    new_title   = 'foo_TITLE_bar'
    field_title = 'hydrus_item_related_item_title_0'

    should_visit_edit_page(@hi)

    expect(find_field(field_link).value).to eq(orig_link)
    expect(find_field(field_title).value).to eq(orig_title)

    fill_in(field_link,  with: new_link)
    fill_in(field_title, with: new_title)
    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)

    # Confirm new content in fedora.
    @hi = Hydrus::Item.find(@druid)
    expect(@hi.descMetadata.relatedItem.titleInfo.title.first).to eq(new_title)
    @hi.descMetadata.relatedItem.location.url.first == new_link
  end

  it 'Related Content adding and deleting' do
    # Got to edit page.
    should_visit_edit_page(@hi)
    # Check for the related item input fields.
    expect(page).to have_css('input#hydrus_item_related_item_title_0')
    expect(page).to have_css('input#hydrus_item_related_item_url_0')
    expect(page).to have_css('#remove_relatedItem_0')
    expect(page).to have_css('input#hydrus_item_related_item_title_1')
    expect(page).to have_css('input#hydrus_item_related_item_url_1')
    expect(page).to have_css('#remove_relatedItem_1')
    expect(page).not_to have_css('#hydrus_item_related_item_title_2')
    expect(page).not_to have_css('#hydrus_item_related_item_url_2')
    expect(page).not_to have_css('#remove_relatedItem_2')
    # Add a new related item
    click_button 'add_link'
    expect(page).to have_css('#hydrus_item_related_item_title_2')
    expect(page).to have_css('#hydrus_item_related_item_url_2')
    expect(page).to have_css('#remove_relatedItem_2')
    fill_in('hydrus_item_related_item_title_2', with: 'Library Website')
    fill_in('hydrus_item_related_item_url_2', with: 'http://library.stanford.edu')
    # Save.
    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)
    # Make sure the descMetadata has the expected N of relatedItem nodes.
    # At one point we had a bug where the new title and url were added
    # to the first node rather than the new empty node.
    @hi = Hydrus::Item.find(@hi.pid)
    expect(@hi.descMetadata.find_by_terms(:relatedItem).size).to eq(3)
    # Revisit edit page and check for the values we just added.
    should_visit_edit_page(@hi)
    expect(page).to have_css('#remove_relatedItem_2')
    expect(find_field('hydrus_item_related_item_title_2').value).to eq('Library Website')
    expect(find_field('hydrus_item_related_item_url_2').value).to eq('http://library.stanford.edu')
    # Delete the item we added.
    click_link 'remove_relatedItem_2'
    expect(current_path).to eq(edit_polymorphic_path(@hi))
    expect(page).not_to have_css('#hydrus_item_related_item_title_2')
    expect(page).not_to have_css('#hydrus_item_related_item_url_2')
    expect(page).not_to have_css('#remove_relatedItem_2')
  end

  it 'editing related content w/o titles' do
    # Save copy of the original datastreams.
    @druid = 'druid:oo000oo0005'
    @hi    = Hydrus::Item.find(@druid)
    # Set up the new values for the fields we will edit.
    ni = OpenStruct.new(
      ri_title: 'My URL title',
      ri_url: 'http://stanford.and.son',
      title_f: 'hydrus_item_related_item_title_0',
      url_f: 'hydrus_item_related_item_url_0',
    )
    # Visit edit page.
    should_visit_edit_page(@hi)
    # Make sure the object does not have the new content yet.
    old_title = find_field(ni.title_f).value
    old_url = find_field(ni.url_f).value
    expect(old_title).to be_blank
    expect(old_url).not_to eq(ni.ri_url)
    # Submit some changes.
    fill_in ni.title_f, with: ni.ri_title
    fill_in ni.url_f, with: ni.ri_url
    click_button(@buttons[:save])
    # Confirm new location and flash message.
    expect(current_path).to eq(polymorphic_path(@hi))
    expect(page).to have_content(@ok_notice)
    # Confirm new content in fedora.
    @hi = Hydrus::Item.find(@druid)
    expect(@hi.related_item_title.first).to eq(ni.ri_title)
  end

  it 'can edit preferred citation field' do
    citation_field = 'hydrus_item_preferred_citation'
    new_pref_cit  = 'new_citation_FOO'
    orig_pref_cit = @hi.preferred_citation

    should_visit_edit_page(@hi)

    expect(find_field(citation_field).value.strip).to eq(orig_pref_cit)
    fill_in citation_field, with: new_pref_cit
    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)

    # Confirm new content in fedora.
    @hi = Hydrus::Item.find(@druid)
    @hi.preferred_citation == new_pref_cit
  end

  it 'Related citation adding and deleting' do
    new_citation         = 'hydrus_item_related_citation_2'
    new_delete_button    = 'remove_related_citation_2'
    new_citation_text    = ' This is a citation for a related item! '

    should_visit_edit_page(@hi)

    expect(page).to have_css('textarea#hydrus_item_related_citation_0')
    expect(page).to have_css('textarea#hydrus_item_related_citation_1')

    expect(page).not_to have_css("textarea##{new_citation}")
    expect(page).not_to have_css("##{new_delete_button}")

    click_button 'add_related_citation'
    expect(current_path).to eq(edit_polymorphic_path(@hi))

    expect(page).to have_css("##{new_citation}")
    expect(page).to have_css("##{new_delete_button}")

    fill_in(new_citation, with: new_citation_text)

    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)

    should_visit_edit_page(@hi)

    expect(page).to have_css("##{new_delete_button}")
    expect(find_field(new_citation).value.strip).to eq(new_citation_text.strip)

    # delete
    click_link new_delete_button

    expect(current_path).to eq(edit_polymorphic_path(@hi))
    expect(page).not_to have_css("##{new_citation}")
    expect(page).not_to have_css("##{new_delete_button}")
  end

  it "should have editible license information once the parent collection's license is set to varies" do
    varies_radio           = 'hydrus_collection_license_option_varies'
    collection_licenses    = 'license_option_varies'
    new_collection_license = 'CC BY Attribution'
    item_licenses          = 'hydrus_item_license'
    new_item_license       = 'PDDL Public Domain Dedication and License'
    no_license             = 'No license'
    css_lic_select         = "optgroup/option[@selected='selected']"

    # Item has expected rights.
    ps = { embargo_date: '', visibility: 'world', license_code: 'cc-by' }
    check_emb_vis_lic(@hi, ps)

    # Modify the collection to allow varying license.
    should_visit_edit_page(Hydrus::Collection.find('druid:oo000oo0003'))
    choose varies_radio
    select(new_collection_license, from: collection_licenses)
    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)

    # Item edit page should offer ability to select a license.
    should_visit_edit_page(@hi)
    expect(page).to have_selector("##{item_licenses}")

    # Verify that the default license set at the collection-level is selected.
    within("select##{item_licenses}") do
      selected_license = find(css_lic_select).text
      expect(selected_license).to eq(new_collection_license)
    end

    # Select a different license, and save.
    select(new_item_license, from: item_licenses)
    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)

    # Item has expected rights.
    @hi = Hydrus::Item.find @druid
    ps = { embargo_date: '', visibility: 'world', license_code: 'pddl' }
    check_emb_vis_lic(@hi, ps)

    # Back to the edit page.
    should_visit_edit_page(@hi)

    # Verify that the previous license was set.
    within("select##{item_licenses}") do
      selected_license = find(css_lic_select).text
      expect(selected_license).to eq(new_item_license)
    end

    # Select no license, and save.
    select(no_license, from: item_licenses)
    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)

    # Back to the edit page.
    should_visit_edit_page(@hi)

    # Verify that the previous license was set.
    within("select##{item_licenses}") do
      selected_license = find(css_lic_select).text
      expect(selected_license).to eq(no_license)
    end

    # Select original license, and save.
    select(new_collection_license, from: item_licenses)
    click_button(@buttons[:save])
    expect(page).to have_content(@ok_notice)

    # Back to the edit page.
    should_visit_edit_page(@hi)

    # Verify that the previous license was set.
    within("select##{item_licenses}") do
      selected_license = find(css_lic_select).text
      expect(selected_license).to eq(new_collection_license)
    end
  end

  describe 'role-protection' do
    let(:owner) { create :archivist1 }
    let(:reviewer) { create :archivist5 }
    let(:viewer) { create :archivist7 }
    before(:each) do
      @prev_mint_ids = config_mint_ids()
    end

    after(:each) do
      config_mint_ids(@prev_mint_ids)
    end

    it 'action buttons should not be accessible to users with insufficient powers' do
      sign_out
      # Create an item.
      hi = create_new_item()

      # Submit for approval.
      # A viewer should not see the button.
      b = @buttons[:submit_for_approval]
      sign_in(viewer)
      should_visit_view_page(hi)
      expect(page).not_to have_button(b)

      # But the owner should see the button.
      # Submit it for approval.
      sign_in(owner)
      should_visit_view_page(hi)
      click_button(b)

      # Disapprove item.
      # A viewer should not see the button.
      b = @buttons[:disapprove]
      sign_in(viewer)
      should_visit_view_page(hi)
      expect(page).not_to have_button(b)

      # But the reviewer should see the button.
      # Disapprove the item.
      sign_in(reviewer)
      should_visit_view_page(hi)
      fill_in 'hydrus_item_disapproval_reason', with: 'Doh!'
      click_button(b)

      # Resubmit item.
      # A viewer should not see the button.
      b = @buttons[:resubmit]
      sign_in(viewer)
      should_visit_view_page(hi)
      expect(page).not_to have_button(b)

      # But the owner should see the button.
      # Resubmit the item.
      sign_in(owner)
      should_visit_view_page(hi)
      click_button(b)

      # Approve item.
      # A viewer should not see the button.
      b = @buttons[:approve]
      sign_in(viewer)
      should_visit_view_page(hi)
      expect(page).not_to have_button(b)

      # But the reviewer should see the button.
      # Disapprove the item.
      sign_in(reviewer)
      should_visit_view_page(hi)
      click_button(b)

      # Create another item, one not requiring review.
      hi = create_new_item(requires_human_approval: 'no')

      # Publish directly.
      # A viewer should not see the button.
      b = @buttons[:publish_directly]
      sign_in(viewer)
      should_visit_view_page(hi)
      expect(page).not_to have_button(b)

      # But the owner should see the button.
      # Publish directly.
      sign_in(owner)
      should_visit_view_page(hi)
      click_button(b)
    end
  end

  describe 'embargo and visibility' do
    it 'setting/removing embargo date modifies embargoMD and rightsMD as expected' do
      css = {
        emb_yes: 'hydrus_item_embarg_visib_embargoed_yes',
        emb_no: 'hydrus_item_embarg_visib_embargoed_no',
        visib: 'hydrus_item_embarg_visib_visibility',
        emb_date: 'hydrus_item_embarg_visib_date',
      }
      lic = 'cc-by'

      # Change collection to allow for variable visibility for its items.
      hc = @hi.collection
      hc.visibility_option_value = 'varies'
      hc.save

      # Reset the Item's publish time, so this test won't fail a year from now.
      today    = HyTime.now.beginning_of_day
      later    = today + 10.days
      later_dt = HyTime.datetime(later, from_localzone: true)
      later_d  = HyTime.date(later, from_localzone: true)
      @hi.initial_submitted_for_publish_time = HyTime.datetime(today, from_localzone: true)
      @hi.save

      # Check embargoMD and rightsMD: initial.
      check_emb_vis_lic(@hi,
                        embargo_date: '',
                        visibility: 'world',
                        license_code: lic,)

      # Visit edit page: set an embargo date and change visibility.
      should_visit_edit_page(@hi)
      choose(css[:emb_yes])
      fill_in(css[:emb_date], with: later_d)
      select('Stanford only', from: css[:visib])

      # Save and confirm.
      click_button(@buttons[:save])
      expect(current_path).to eq(polymorphic_path(@hi))
      expect(page).to have_content(@ok_notice)

      # Check embargoMD and rightsMD: after setting an embargo date.
      @hi = Hydrus::Item.find(@hi.pid)
      check_emb_vis_lic(@hi,
                        embargo_date: later_dt,
                        visibility: 'stanford',
                        license_code: lic,)

      # Visit edit page: remove embargo.
      should_visit_edit_page(@hi)
      choose(css[:emb_no])

      # Save and confirm.
      click_button(@buttons[:save])
      expect(current_path).to eq(polymorphic_path(@hi))
      expect(page).to have_content(@ok_notice)

      # Check embargoMD and rightsMD: after removing embargo.
      @hi = Hydrus::Item.find(@hi.pid)
      check_emb_vis_lic(@hi,
                        embargo_date: '',
                        visibility: 'stanford',
                        license_code: lic,)
    end
  end

  describe 'uploaded files' do
    it 'hide indicator on view page' do
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
          expect(find("#{span}.file_label_#{id}")).to have_content(lab)
          txt = find("#{span}.hide_status_#{id}").text
          expect(txt.include?('[hidden]')).to eq(hid)
          # Check ObjectFile.
          hof = Hydrus::ObjectFile.find(id)
          expect(hof.get_file_info).to eq(fi)
        end
        # Check total N of ObjectFiles.
        expect(Hydrus::ObjectFile.where(pid: @hi.pid).size).to eq(exp.keys.size)
      }

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
        expect(find_by_id(css_lab).value).to eq(fi[:label])

        if fi[:hide]
          expect(find_by_id(css_hid)).to be_checked
        else
          expect(find_by_id(css_hid)).to_not be_checked
        end

        # Modify the values -- in the exp hash.
        lab = 'foo_' + fi[:label]
        hid = (id < 3)
        exp[id][:label] = lab
        exp[id][:hide]  = hid
        # Modify the values -- in the web form.
        fill_in(css_lab, with: lab)
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
      expect(page.has_link?(css_del)).to eq(false)

      # Visit view page and check file info.
      should_visit_view_page(@hi)
      check_file_info.call(exp)

      # Restore the deleted file.
      restore_upload_file(file_url)
      expect(File.exists?('public' + file_url)).to eq(true)
    end
  end
end
