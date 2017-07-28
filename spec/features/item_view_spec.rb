# frozen_string_literal: true
require 'spec_helper'

describe('Item view', type: :request, integration: true) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
  end

  it 'If not logged in, should be redirected to the login page, then back to our intended page after logging in' do
    logout
    visit "/items/#{@druid}"
    expect(current_path).to eq(new_user_session_path)
    fill_in 'Email', with: 'archivist1@example.com'
    fill_in 'Password', with: login_pw
    click_button 'Sign in'
    expect(current_path).to eq(polymorphic_path(@hi))
  end

  it 'Breadcrumbs should be displayed with home link, linked trucated collection name, and unlinked item name with state' do
    login_as('archivist1')
    visit polymorphic_path(@hi)
    expect(page).to have_selector('ul.breadcrumb li a', text: 'Home')
    expect(page).to have_selector('ul.breadcrumb li a', text: 'SSDS Social Science Data Co...')
    expect(page).to have_selector('ul.breadcrumb li', text: 'How Couples Meet and Stay T... (published)')
  end

  it 'should redirect to the item page if the requested druid is an item but is visited at the collection page URL' do
    @bad_url = "/collections/#{@druid}" # this is actually an item druid
    login_as('archivist1')
    visit @bad_url
    expect(current_path).to eq(polymorphic_path(@hi))
  end

  it 'Some of the expected info is displayed, and disappers if blank' do
    login_as('archivist1')
    visit polymorphic_path(@hi)
    expect(current_path).to eq(polymorphic_path(@hi))
    expect(page).to have_content('archivist1@example.com')
    expect(page).to have_content('How Couples Meet and Stay Together')
    expect(page).to have_content('The story of Pinocchio')
    expect(page).to have_content('druid:oo000oo0001')
    expect(page).to have_content('Contributing author')
    expect(page).to have_content('Frisbee, Hanna')
    expect(page).to have_content('Sponsor')
    expect(page).to have_content('US National Science Foundation, award SES-0751613')
    expect(page).to have_content('wooden boys')
    expect(page).to have_content('Keywords')
    expect(page).to have_content('pinocchio.htm')

    # Now let's delete the related items and go back to the
    # view page and make sure those fields don't show up.
    should_visit_edit_page(@hi)
    click_link 'remove_relatedItem_0' # remove both related items
    click_link 'remove_relatedItem_0'
    click_button 'save_nojs'
    should_visit_view_page(@hi)
    expect(page).not_to have_content('Related links')
    expect(page).not_to have_content('story by Jennifer Ludden August 16, 2010')
  end

  it 'should apply the active class to the active tab' do
    login_as('archivist1')
    should_visit_view_page(@hi)
    expect(page).to have_selector('ul.nav li.active', text: 'Published Version')

    should_visit_view_page([@hi, :events])
    expect(page).to have_selector('ul.nav li.active', text: 'History')
  end

  it 'should show the events in a history tab' do
    login_as('archivist1')
    should_visit_view_page([@hi, :events])
    expect(page).to have_content('How Couples Meet and Stay Together')
    expect(page).to have_content('Event History for this Item')
    expect(page).to have_content('Item created')
  end

  it 'redirect_if_not_correct_object_type()' do
    login_as('archivist1')
    # View item URL with a collection PID.
    visit '/items/druid:oo000oo0003'
    expect(current_path).to eq('/collections/druid:oo000oo0003')
    # Edit collection URL with an item PID.
    visit '/collections/druid:oo000oo0001/edit'
    expect(current_path).to eq('/items/druid:oo000oo0001/edit')
  end

  it 'can exercise purl_page_ready?' do
    # Our fixture object is not on PURL.
    expect(@hi.purl_page_ready?).to eq(false)
    # But this pid does exist on purl-test.
    allow(@hi).to receive(:purl_url).and_return('https://purl-test.stanford.edu/pf182cd5962.xml')
    expect(@hi.purl_page_ready?).to eq(true)
  end
end
