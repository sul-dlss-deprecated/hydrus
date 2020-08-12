# frozen_string_literal: true

class DefaultObjectRightsDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for defaultObjectRights
  def to_solr
    resource.defaultObjectRights.to_solr
  end
end
