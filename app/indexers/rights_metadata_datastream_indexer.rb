# frozen_string_literal: true

class RightsMetadataDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for rightsMetadata
  def to_solr
    resource.rightsMetadata.to_solr
  end
end
