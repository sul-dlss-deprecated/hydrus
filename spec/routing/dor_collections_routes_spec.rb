require 'spec_helper'

describe "collection routes" do
  
  it "show page should route correctly" do
    druid = 'druid:sw909tc7852'
    h = { :get => "/collections/#{druid}" }
    h.should route_to(
        :controller => "dor_collections",
        :id         => druid,
        :action     => "show"
    )
  end

  it "edit page should route correctly" do
    druid = 'druid:sw909tc7852'
    h = { :get => "/collections/#{druid}/edit" }
    h.should route_to(
        :controller => "dor_collections",
        :id         => druid,
        :action     => "edit"
    )
  end

end

describe "named route hacks" do
  
  include Hydrus::RoutingHacks
  include ActionDispatch::Routing::PolymorphicRoutes

  before (:each) do
    @has_model_s = 'info:fedora/afmodel:Dor_Collection'
    @druid       = 'druid:sw909tc7852'
  end

  it "should be able to exercise all of the routing hacks" do
    sdoc    = SolrDocument.new(:has_model_s => @has_model_s, :id => @druid)
    mock_dc = mock_model('DorCollection', :id => @druid)
    h       = { :id => @druid }
    tests   = [
      [ 'catalog',          sdoc,     'dor_collections', 'show' ],
      [ 'catalog',          h,        'catalog',         'show' ],
      [ 'catalog',          @druid,   'catalog',         'show' ],
      [ 'catalog',          mock_dc,  'dor_collections', 'show' ],

      [ 'solr_document',    h,        'catalog',         'show' ],
      [ 'solr_document',    sdoc,     'dor_collections', 'show' ],

      [ 'edit_catalog',     sdoc,     'dor_collections', 'edit' ],
      [ 'edit_catalog',     h,        'catalog',         'edit' ],
      [ 'edit_catalog',     @druid,   'catalog',         'edit' ],
      [ 'edit_catalog',     mock_dc,  'dor_collections', 'edit' ],

      [ 'polymorphic',      sdoc,     'dor_collections', 'show' ],
      [ 'edit_polymorphic', sdoc,     'dor_collections', 'edit' ],
    ]
    tests.each do |meth, arg, exp_controller, exp_action|
      %w(_path _url).each do |meth_suffix|
        arg = arg.merge({:host => 'localhost'}) if(
          meth_suffix == '_url' and 
          arg.class == Hash
        )
        route_hash = { :get => send(meth + meth_suffix, arg, :host => 'localhost') }
        route_hash.should route_to(
          :controller => exp_controller,
          :action     => exp_action,
          :id         => @druid
        )
      end
    end
  end

  # Not sure if this is the desired behavior, but it is the current implementation.
  it "catalog_path() with a SolrDocument lacking a model should raise" do
    h = { :id => @druid }
    sdoc = SolrDocument.new h
    expect { catalog_path(sdoc) }.to raise_error
  end

end
