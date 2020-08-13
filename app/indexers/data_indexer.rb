# frozen_string_literal: true

# Indexing provided by ActiveFedora
class DataIndexer
  include ActiveFedora::Indexing

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # we need to override this until https://github.com/samvera/active_fedora/pull/1371
  # has been released
  def to_solr(solr_doc = {})
    c_time = create_date
    c_time = Time.parse(c_time) unless c_time.is_a?(Time)
    m_time = modified_date
    m_time = Time.parse(m_time) unless m_time.is_a?(Time)
    Solrizer.set_field(solr_doc, 'system_create', c_time, :stored_sortable)
    Solrizer.set_field(solr_doc, 'system_modified', m_time, :stored_sortable)
    Solrizer.set_field(solr_doc, 'object_state', state, :stored_sortable)
    Solrizer.set_field(solr_doc, 'active_fedora_model', has_model, :stored_sortable)
    solr_doc[SOLR_DOCUMENT_ID.to_sym] = pid
    solr_doc = solrize_relationships(solr_doc)
    solr_doc
  end

  delegate :create_date, :modified_date, :state, :pid, :inner_object,
           :datastreams, :relationships, :has_model, to: :resource
end
