# frozen_string_literal: true

class DescriptiveMetadataDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for descMetadata
  def to_solr
    resource.descMetadata.to_solr
  end
end
