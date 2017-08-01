# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'hydrus_items/add_contributor.js.erb' do
  before do
    params[:id] = '7777'
    render template: 'hydrus_items/add_contributor', locals: { index: 1, guid: 999 }
  end

  it 'renders the response' do
    expect(rendered).to start_with '$(".contributor-select #add_contributor").before('
  end
end
