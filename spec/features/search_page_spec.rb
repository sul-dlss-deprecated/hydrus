require 'spec_helper'

describe('Search page', type: :request, integration: true) do

  it 'Some results should appear for archivist1 user for default search' do
    pending('removed search pending decision on if and where to show it')
    visit root_path
    login_as('archivist1')
    click_button('search')
    docs = find 'div#documents'
    expect(docs).to have_content 'How Couples Meet'
    expect(docs).to have_content 'SSDS Social Science Data Collection'
  end

end
