# frozen_string_literal: true

class ProvenanceMetadataDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for provenanceMetadata
  def to_solr
    resource.provenanceMetadata.to_solr
  end
end
