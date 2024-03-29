require 'spec_helper'

RSpec.describe('Collection view', type: :request, integration: true) do
  let(:archivist1) { create :archivist1 }

  before do
    @apo_druid = 'druid:bb000bb0002'
    @druid = 'druid:bb000bb0003'
    @druid_no_files = 'druid:bb000bb0004'
    @hc = Hydrus::Collection.find @druid
  end

  it 'Breadcrumbs should be displayed with home link and unlinked trucated collection name' do
    sign_in(archivist1)
    visit polymorphic_path(@hc)
    expect(page).to have_selector('ul.breadcrumb li a', text: 'Home')
    expect(page).to have_selector('ul.breadcrumb li', text: 'SSDS Social Science Data Co...')
  end

  it 'should redirect to the collection page if the requested druid is a collection but is visited at the item page URL' do
    @bad_url = "/items/#{@druid}" # this is actually a collection druid
    sign_in(archivist1)
    visit @bad_url
    expect(current_path).to eq(polymorphic_path(@hc))
  end

  it 'should show info from the Collection' do
    sign_in(archivist1)
    visit polymorphic_path(@hc)
    expect(current_path).to eq(polymorphic_path(@hc))
    expect(page).to have_content('SSDS Social Science Data Collection')
    expect(page).to have_content('Described as')
  end

  it 'should show info from the Items of the Collection' do
    sign_in(archivist1)
    visit polymorphic_path([@hc, :items])
    coll_items = find('div#items')
    expect(coll_items).to have_content('How Couples Meet and Stay Together')
    expect(coll_items).to have_content('Ethnic Collective Action')
    expect(coll_items).to have_content('archivist3')
  end

  it 'should show the events in a history tab' do
    sign_in(archivist1)
    visit polymorphic_path([@hc, :events])
    expect(current_path).to eq(polymorphic_path([@hc, :events]))
    coll_items = find('div.event-history')
    expect(coll_items).to have_content('Collection created')
    expect(coll_items).to have_content('archivist1')
  end

  it 'display of visibility options stanford / fixed' do
    sign_in(archivist1)
    @hc.visibility = 'stanford'
    @hc.visibility_option = 'fixed'
    @hc.save
    should_visit_view_page(@hc)
    expect(find('div.release-visibility-view')).to have_content('all items will be visible only to Stanford')
  end

  it 'display of visibility options world / varies' do
    sign_in(archivist1)
    @hc.visibility = 'world'
    @hc.visibility_option = 'varies'
    @hc.save
    should_visit_view_page(@hc)
    expect(find('div.release-visibility-view')).to have_content('but individual items may restrict visibility')
  end

  it 'display of visibility options world / fixed' do
    sign_in(archivist1)
    @hc.visibility = 'world'
    @hc.visibility_option = 'fixed'
    @hc.save
    should_visit_view_page(@hc)
    expect(find('div.release-visibility-view')).to have_content('all items will be visible to everybody')
  end
end
