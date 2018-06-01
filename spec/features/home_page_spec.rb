require 'spec_helper'

describe('Home page', type: :request, integration: true) do
  let(:archivist1) { create :archivist1 }
  let(:archivist2) { create :archivist2 }
  let(:archivist3) { create :archivist3 }
  before(:each) do
    @search_box  = '.search-query-form #search'
    @sdr         = 'Stanford Digital Repository'
    @your_cs     = 'Your Active Collections'
    @breadcrumbs = 'ul.breadcrumb li a'
    @cc_button   = 'a.btn[href="/collections/new"]'
    @alert       = 'div.alert'
    @search_url  = '/catalog?q=&search_field=text&commit=search'
    @sign_in_msg = 'You must sign in'
  end

  it 'if not logged in, should see intro text, but not other controls' do
    sign_out
    visit root_path
    expect(page).to have_content(@sdr)
    expect(page).not_to have_content(@your_cs)
    expect(page).to have_no_selector(@search_box)
    expect(page).not_to have_button(@cc_button)
  end

  it 'if logged in, should see intro text, search box, and listing of collections' do
    sign_in(archivist1)
    visit root_path
    expect(page).to have_content(@sdr)
    expect(page).to have_content(@your_cs)
    # page.should have_selector(@search_box)
  end

  context 'as archivist1' do
    before do
      sign_in(archivist1)
    end

    it 'shows collections' do
      visit root_path
      expect(find('div.user-collections')).to have_xpath("//a[@href='/collections/druid:oo000oo0003']")
      expect(find('div.user-collections')).to have_xpath("//a[@href='/collections/druid:oo000oo0004']")
      expect(find('div.user-collections')).to have_xpath("//a[@href='/collections/druid:oo000oo0010']")
    end

    it 'restricts search results' do
      visit(@search_url)
      expect(find('.page_links')).to have_content('1 - 10 of 10')
    end

    it 'has a button to create a new collection' do
      visit root_path
      expect(page).to have_selector(@cc_button)
    end
  end

  context 'as archivist2' do
    before do
      sign_in(archivist2)
    end

    it 'shows the collections they have access to' do
      visit root_path
      expect(find('div.user-collections')).to have_xpath("//a[@href='/collections/druid:oo000oo0003']")
      expect(find('div.user-collections')).not_to have_xpath("//a[@href='/collections/druid:oo000oo0004']")
      expect(find('div.user-collections')).to have_xpath("//a[@href='/collections/druid:oo000oo0010']")
    end

    it 'restricts search results' do
      visit(@search_url)
      expect(find('.page_links')).to have_content('1 - 9 of 9')
    end
  end

  it 'breadcrumbs should not be displayed' do
    # Logged out
    logout
    visit root_path
    expect(page).not_to have_css(@breadcrumbs)
  end

  it 'should not show Create Collection button if user has no authority to create collections' do
    # No
    sign_in(archivist3)
    visit root_path
    expect(page).not_to have_selector(@cc_button)
  end
end
