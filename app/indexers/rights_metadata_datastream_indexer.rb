# frozen_string_literal: true

class RightsMetadataDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for rightsMetadata
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def to_solr
    solr_doc = {
      'copyright_ssim' => resource.rightsMetadata.copyright,
      'use_statement_ssim' => resource.rightsMetadata.use_statement
    }

    dra = resource.rightsMetadata.dra_object
    solr_doc['rights_primary_ssi'] = dra.index_elements[:primary]
    solr_doc['rights_errors_ssim'] = dra.index_elements[:errors] unless dra.index_elements[:errors].empty?
    solr_doc['rights_characteristics_ssim'] = dra.index_elements[:terms] unless dra.index_elements[:terms].empty?

    solr_doc['rights_descriptions_ssim'] = [
      dra.index_elements[:primary],

      (dra.index_elements[:obj_locations_qualified] || []).map do |rights_info|
        rule_suffix = rights_info[:rule] ? " (#{rights_info[:rule]})" : ''
        "location: #{rights_info[:location]}#{rule_suffix}"
      end,
      (dra.index_elements[:file_locations_qualified] || []).map do |rights_info|
        rule_suffix = rights_info[:rule] ? " (#{rights_info[:rule]})" : ''
        "location: #{rights_info[:location]} (file)#{rule_suffix}"
      end,

      (dra.index_elements[:obj_agents_qualified] || []).map do |rights_info|
        rule_suffix = rights_info[:rule] ? " (#{rights_info[:rule]})" : ''
        "agent: #{rights_info[:agent]}#{rule_suffix}"
      end,
      (dra.index_elements[:file_agents_qualified] || []).map do |rights_info|
        rule_suffix = rights_info[:rule] ? " (#{rights_info[:rule]})" : ''
        "agent: #{rights_info[:agent]} (file)#{rule_suffix}"
      end,

      (dra.index_elements[:obj_groups_qualified] || []).map do |rights_info|
        rule_suffix = rights_info[:rule] ? " (#{rights_info[:rule]})" : ''
        "#{rights_info[:group]}#{rule_suffix}"
      end,
      (dra.index_elements[:file_groups_qualified] || []).map do |rights_info|
        rule_suffix = rights_info[:rule] ? " (#{rights_info[:rule]})" : ''
        "#{rights_info[:group]} (file)#{rule_suffix}"
      end,

      (dra.index_elements[:obj_world_qualified] || []).map do |rights_info|
        rule_suffix = rights_info[:rule] ? " (#{rights_info[:rule]})" : ''
        "world#{rule_suffix}"
      end,
      (dra.index_elements[:file_world_qualified] || []).map do |rights_info|
        rule_suffix = rights_info[:rule] ? " (#{rights_info[:rule]})" : ''
        "world (file)#{rule_suffix}"
      end
    ].flatten.uniq

    # these two values are returned by index_elements[:primary], but are just a less granular version of
    # what the other more specific fields return, so discard them
    solr_doc['rights_descriptions_ssim'] -= %w[access_restricted access_restricted_qualified world_qualified]
    solr_doc['rights_descriptions_ssim'] += ['dark (file)'] if dra.index_elements[:terms].include? 'none_read_file'

    solr_doc['obj_rights_locations_ssim'] = dra.index_elements[:obj_locations] if dra.index_elements[:obj_locations].present?
    solr_doc['file_rights_locations_ssim'] = dra.index_elements[:file_locations] if dra.index_elements[:file_locations].present?
    solr_doc['obj_rights_agents_ssim'] = dra.index_elements[:obj_agents] if dra.index_elements[:obj_agents].present?
    solr_doc['file_rights_agents_ssim'] = dra.index_elements[:file_agents] if dra.index_elements[:file_agents].present?

    # suppress empties
    %w[use_statement_ssim copyright_ssim].each do |key|
      solr_doc[key] = solr_doc[key].reject(&:blank?).flatten unless solr_doc[key].nil?
    end

    solr_doc['use_license_machine_ssi'] = resource.rightsMetadata.use_license.first

    # TODO: I don't think this is used in argo, and can be removed
    solr_doc['use_licenses_machine_ssim'] = resource.rightsMetadata.use_license

    solr_doc
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
end
