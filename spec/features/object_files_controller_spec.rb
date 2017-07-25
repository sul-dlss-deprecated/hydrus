require 'spec_helper'

describe('Object Files Download', type: :request, integration: true) do
  fixtures :object_files
  let(:archivist1) { create :archivist1 }
  let(:archivist99) { create :archivist99 }

  before :each do
    @druid = 'druid:bb123bb1234'
    @file = Hydrus::ObjectFile.find(3) # this txt file defined in the fixtures belongs to archivist1
  end

  it 'allows the owner of the file to download it' do
    sign_in(archivist1) # owner of the item can download the file
    visit @file.url
    expect(page.status_code).to eq(200)
    expect(page.response_headers['Content-Type']).to eq('text/plain')
    logout(archivist1)
  end

  it 'redirects to home page with not authorized message when accessing a file URL when no access is allowed' do
    sign_in(archivist99) # no view access on the item, no access
    visit @file.url
    expect(page.response_headers['Content-Type']).not_to eq('text/plain')
    expect(current_path).to eq(root_path)
    expect(find('#flash-notices div.alert')).to have_content('You are not authorized to access this page.')
    logout(archivist99)
    visit @file.url
    expect(current_path).to eq(root_path) # logged out, still can't get the file
  end
end
