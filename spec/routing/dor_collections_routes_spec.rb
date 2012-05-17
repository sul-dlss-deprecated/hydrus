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

  describe "named route hacks" do
    
    include Hydrus::RoutingHacks
    include ActionDispatch::Routing::PolymorphicRoutes

    before (:each) do
      @has_model_s = 'info:fedora/afmodel:Dor_Collection'
      @druid       = 'druid:sw909tc7852'
    end

    it "catalog_path() with SolrDocument" do
      h = { :has_model_s => @has_model_s, :id => @druid }
      sdoc = SolrDocument.new h
      { :get => catalog_path(sdoc) }.should route_to(
        :controller => "dor_collections",
        :id         => @druid,
        :action     => "show"
      )
    end

    it "catalog_path() with DorCollection" do
      h = { :has_model_s => @has_model_s, :id => @druid }
      dorc = mock_model('DorCollection', :id => @druid)
      { :get => catalog_path(dorc) }.should route_to(
        :controller => "dor_collections",
        :id         => @druid,
        :action     => "show"
      )
    end

    it "catalog_path() with Hash" do
      { :get => catalog_path(:id => @druid) }.should route_to(
        :controller => "catalog",
        :id         => @druid,
        :action     => "show"
      )
    end

    it "catalog_path() with Hash" do
      { :get => catalog_path(@druid) }.should route_to(
        :controller => "catalog",
        :id         => @druid,
        :action     => "show"
      )
    end

    it "edit_catalog_path() with SolrDocument" do
      h = { :has_model_s => @has_model_s, :id => @druid }
      sdoc = SolrDocument.new h
      { :get => edit_catalog_path(sdoc) }.should route_to(
        :controller => "dor_collections",
        :id         => @druid,
        :action     => "edit"
      )
    end

    it "polymorphic_path() with SolrDocument" do
      h = { :has_model_s => @has_model_s, :id => @druid }
      sdoc = SolrDocument.new h
      { :get => polymorphic_path(sdoc) }.should route_to(
        :controller => "dor_collections",
        :id         => @druid,
        :action     => "show"
      )
    end

    it "edit_polymorphic_path() with SolrDocument" do
      h = { :has_model_s => @has_model_s, :id => @druid }
      sdoc = SolrDocument.new h
      { :get => edit_polymorphic_path(sdoc) }.should route_to(
        :controller => "dor_collections",
        :id         => @druid,
        :action     => "edit"
      )
    end

    it "solr_document_path() with Hash" do
      h = { :has_model_s => @has_model_s, :id => @druid }
      { :get => solr_document_path(:id => @druid) }.should route_to(
        :controller => "catalog",
        :id         => @druid,
        :action     => "show"
      )
    end

    # Not sure if this is the desired behavior, but it is the current implementation.
    it "catalog_path() with a SolrDocument lacking a model should raise" do
      h = { :id => @druid }
      sdoc = SolrDocument.new h
      expect { catalog_path(sdoc) }.to raise_error
    end

  end

end
