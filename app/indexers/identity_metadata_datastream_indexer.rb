# frozen_string_literal: true

class IdentityMetadataDatastreamIndexer
  include SolrDocHelper

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for identityMetadata
  def to_solr
    solr_doc = {}
    solr_doc['objectType_ssim'] = resource.identityMetadata.objectType

    plain_identifiers = []
    ns_identifiers = []
    if source_id.present?
      (name, id) = source_id.split(/:/, 2)
      plain_identifiers << id
      ns_identifiers << source_id
      solr_doc['source_id_ssim'] = [source_id]
    end

    resource.identityMetadata.otherId.compact.each do |qid|
      # this section will solrize barcode and catkey, which live in otherId
      (name, id) = qid.split(/:/, 2)
      plain_identifiers << id
      ns_identifiers << qid
      next unless %w[barcode catkey].include?(name)

      solr_doc["#{name}_id_ssim"] = [id]
    end
    solr_doc['dor_id_tesim'] = plain_identifiers
    solr_doc['identifier_tesim'] = ns_identifiers
    solr_doc['identifier_ssim'] = ns_identifiers

    solr_doc
  end

  private

  def source_id
    @source_id ||= resource.identityMetadata.sourceId
  end
end
