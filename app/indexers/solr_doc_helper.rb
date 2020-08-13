# frozen_string_literal: true

module SolrDocHelper
  def add_solr_value(solr_doc, field_name, value, field_type = :default, index_types = [:searchable])
    case field_type
    when :symbol
      index_types << field_type
    end
    ::Solrizer.insert_field(solr_doc, field_name, value, *index_types)
  end
end
