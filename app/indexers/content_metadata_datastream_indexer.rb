# frozen_string_literal: true

class ContentMetadataDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # @return [Hash] the partial solr document for contentMetadata
  def to_solr
    return {} unless doc.root['type']

    preserved_size = 0
    shelved_size = 0
    counts = Hash.new(0)                # default count is zero
    resource_type_counts = Hash.new(0)  # default count is zero
    file_roles = ::Set.new
    mime_types = ::Set.new
    first_shelved_image = nil

    doc.xpath('contentMetadata/resource').sort { |a, b| a['sequence'].to_i <=> b['sequence'].to_i }.each do |resource|
      counts['resource'] += 1
      resource_type_counts[resource['type']] += 1 if resource['type']
      resource.xpath('file').each do |file|
        counts['content_file'] += 1
        preserved_size += file['size'].to_i if file['preserve'] == 'yes'
        shelved_size += file['size'].to_i if file['shelve'] == 'yes'
        if file['shelve'] == 'yes'
          counts['shelved_file'] += 1
          first_shelved_image ||= file['id'] if file['id'].end_with?('jp2')
        end
        mime_types << file['mimetype']
        file_roles << file['role'] if file['role']
      end
    end
    solr_doc = {
      'content_type_ssim' => doc.root['type'],
      'content_file_mimetypes_ssim' => mime_types.to_a,
      'content_file_count_itsi' => counts['content_file'],
      'shelved_content_file_count_itsi' => counts['shelved_file'],
      'resource_count_itsi' => counts['resource'],
      'preserved_size_dbtsi' => preserved_size, # double (trie) to support very large sizes
      'shelved_size_dbtsi' => shelved_size # double (trie) to support very large sizes
    }
    solr_doc['resource_types_ssim'] = resource_type_counts.keys unless resource_type_counts.empty?
    solr_doc['content_file_roles_ssim'] = file_roles.to_a unless file_roles.empty?
    resource_type_counts.each do |key, count|
      solr_doc["#{key}_resource_count_itsi"] = count
    end
    # first_shelved_image is neither indexed nor multiple
    solr_doc['first_shelved_image_ss'] = first_shelved_image unless first_shelved_image.nil?
    solr_doc
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  private

  def doc
    @doc ||= resource.contentMetadata.ng_xml
  end
end
