# frozen_string_literal: true

class IdentifiableIndexer
  include SolrDocHelper

  INDEX_VERSION_FIELD = 'dor_services_version_ssi'
  NS_HASH = { 'hydra' => 'http://projecthydra.org/ns/relations#',
              'fedora' => 'info:fedora/fedora-system:def/relations-external#',
              'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' }.freeze

  FIELDS = {
    collection: {
      hydrus: 'hydrus_collection_title',
      non_hydrus: 'nonhydrus_collection_title',
      union: 'collection_title'
    },
    apo: {
      hydrus: 'hydrus_apo_title',
      non_hydrus: 'nonhydrus_apo_title',
      union: 'apo_title'
    }
  }.freeze
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  ## Module-level variables, shared between ALL mixin includers (and ALL *their* includers/extenders)!
  ## used for caching found values
  @@collection_hash = {}
  @@apo_hash = {}

  # @return [Hash] the partial solr document for identifiable concerns
  def to_solr
    solr_doc = {}
    solr_doc[INDEX_VERSION_FIELD] = Dor::VERSION
    solr_doc['indexer_host_ssi'] = Socket.gethostname
    solr_doc['indexed_at_dtsi'] = Time.now.utc.xmlschema

    add_solr_value(solr_doc, 'title_sort', resource.label, :string, [:stored_sortable])

    rels_doc = Nokogiri::XML(resource.datastreams['RELS-EXT'].content)
    apos = rels_doc.search('//rdf:RDF/rdf:Description/hydra:isGovernedBy', NS_HASH)
    collections = rels_doc.search('//rdf:RDF/rdf:Description/fedora:isMemberOfCollection', NS_HASH)
    solrize_related_obj_titles(solr_doc, apos, @@apo_hash, :apo)
    solrize_related_obj_titles(solr_doc, collections, @@collection_hash, :collection)
    solr_doc['public_dc_relation_tesim'] ||= solr_doc['collection_title_tesim'] if solr_doc['collection_title_tesim']
    solr_doc['metadata_source_ssi'] = identity_metadata_source
    # This used to be added to the index by https://github.com/sul-dlss/dor-services/commit/11b80d249d19326ef591411ffeb634900e75c2c3
    # and was called dc_identifier_druid_tesim
    # It is used to search based on druid.
    solr_doc['objectId_tesim'] = [resource.pid, resource.pid.split(':').last]
    solr_doc
  end

  # @return [String] calculated value for Solr index
  def identity_metadata_source
    if resource.identityMetadata.otherId('catkey').first ||
       resource.identityMetadata.otherId('barcode').first
      'Symphony'
    else
      'DOR'
    end
  end

  # Clears out the cache of items. Used primarily in testing.
  def self.reset_cache!
    @@collection_hash = {}
    @@apo_hash = {}
  end

  private

  def related_object_tags(object)
    return [] unless object

    Dor::Services::Client.object(object.pid).administrative_tags.list
  end

  # @param [Hash] solr_doc
  # @param [Array] relationships
  # @param [Hash] title_hash a cache for titles
  # @param [Symbol] type either :apo or :collection
  def solrize_related_obj_titles(solr_doc, relationships, title_hash, type)
    # TODO: if you wanted to get a little fancier, you could also solrize a 2 level hierarchy and display using hierarchial facets, like
    # ["SOURCE", "SOURCE : TITLE"] (e.g. ["Hydrus", "Hydrus : Special Collections"], see (exploded) tags in IdentityMetadataDS#to_solr).
    title_type = :symbol # we'll get an _ssim because of the type
    title_attrs = [:stored_searchable] # we'll also get a _tesim from this attr
    relationships.each do |rel_node|
      rel_druid = rel_node['rdf:resource']
      next unless rel_druid # TODO: warning here would also be useful

      rel_druid = rel_druid.gsub('info:fedora/', '')

      # populate cache if necessary
      unless title_hash.key?(rel_druid)
        begin
          related_obj = Dor.find(rel_druid)
          related_obj_title = related_obj_display_title(related_obj, rel_druid)
          is_from_hydrus = related_object_tags(related_obj).include?('Project : Hydrus')
          title_hash[rel_druid] = { 'related_obj_title' => related_obj_title, 'is_from_hydrus' => is_from_hydrus }
        rescue ActiveFedora::ObjectNotFoundError
          # This may happen if the given APO or Collection does not exist (bad data)
          title_hash[rel_druid] = { 'related_obj_title' => rel_druid, 'is_from_hydrus' => false }
        end
      end

      # cache should definitely be populated, so just use that to write solr field
      if title_hash[rel_druid]['is_from_hydrus']
        add_solr_value(solr_doc, FIELDS.dig(type, :hydrus), title_hash[rel_druid]['related_obj_title'], title_type, title_attrs)
      else
        add_solr_value(solr_doc, FIELDS.dig(type, :non_hydrus), title_hash[rel_druid]['related_obj_title'], title_type, title_attrs)
      end
      add_solr_value(solr_doc, FIELDS.dig(type, :union), title_hash[rel_druid]['related_obj_title'], title_type, title_attrs)
    end
  end

  def related_obj_display_title(related_obj, default_title)
    return default_title unless related_obj

    related_obj.full_title || default_title
  end
end
