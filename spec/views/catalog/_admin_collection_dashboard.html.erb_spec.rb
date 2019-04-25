# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'catalog/_admin_collection_dashboard.html.erb' do
  before do
    render 'catalog/admin_collection_dashboard', collections: collections
  end
  let(:collections) { { 'druid:aa111aa1111' => { solr: solr_doc } } }
  let(:solr_doc) do
    SolrDocument.new('titleInfo_title_ssm' => ['', '', 'Le smorfie dei satiri'])
  end

  it 'shows a link' do
    expect(rendered).to have_link 'Le smorfie dei satiri', href: '/collections/druid:aa111aa1111'
    expect(rendered).to have_link 'items', href: '/collections/druid:aa111aa1111/items'
  end
end
