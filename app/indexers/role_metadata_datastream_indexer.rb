# frozen_string_literal: true

class RoleMetadataDatastreamIndexer
  include SolrDocHelper

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for roleMetadata
  def to_solr
    {}.tap do |solr_doc|
      # rubocop:disable Rails/DynamicFindBy
      resource.roleMetadata.find_by_xpath('/roleMetadata/role/*').each do |actor|
        role_type = actor.parent['type']
        val = [actor.at_xpath('identifier/@type'), actor.at_xpath('identifier/text()')].join ':'
        add_solr_value(solr_doc, "apo_role_#{actor.name}_#{role_type}", val, :string, [:symbol])
        add_solr_value(solr_doc, "apo_role_#{role_type}", val, :string, [:symbol])
        add_solr_value(solr_doc, 'apo_register_permissions', val, :string, %i[symbol stored_searchable]) if %w[dor-apo-manager dor-apo-depositor].include? role_type
      end
      # rubocop:enable Rails/DynamicFindBy
    end
  end
end
