# frozen_string_literal: true

class ObjectProfileIndexer
  include SolrDocHelper

  attr_reader :resource

  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for releasable concerns
  def to_solr
    {}.tap do |solr_doc|
      add_solr_value(solr_doc, 'obj_label', resource.label, :symbol, [:stored_searchable])
    end
  end
end
