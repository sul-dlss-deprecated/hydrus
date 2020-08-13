# frozen_string_literal: true

class VersionMetadataDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for versionMetadata
  def to_solr
    resource.versionMetadata.to_solr
  end
end
