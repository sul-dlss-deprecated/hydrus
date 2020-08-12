# frozen_string_literal: true

class AdministrativeMetadataDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for administrativeMetadata
  def to_solr
    resource.administrativeMetadata.to_solr
  end
end
