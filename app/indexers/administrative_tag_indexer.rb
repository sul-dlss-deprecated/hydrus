# frozen_string_literal: true

# Index administrative tags for an object.
# NOTE: Most of this code was extracted from the dor-services gem:
#       https://github.com/sul-dlss/dor-services/blob/v9.0.0/lib/dor/datastreams/identity_metadata_ds.rb#L196-L218
class AdministrativeTagIndexer
  TAG_PART_DELIMITER = ' : '
  TAGS_TO_INDEX = ['Project', 'Registered By'].freeze

  attr_reader :resource

  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for administrative tags
  def to_solr
    solr_doc = { 'tag_ssim' => [], 'exploded_tag_ssim' => [] }
    administrative_tags.each do |tag|
      solr_doc['tag_ssim'] << tag
      solr_doc['exploded_tag_ssim'] += exploded_tags_from(tag)

      tag_prefix, rest = tag.split(TAG_PART_DELIMITER, 2)
      next if !TAGS_TO_INDEX.include?(tag_prefix) || rest.nil?

      prefix = tag_prefix.downcase.strip.gsub(/\s/, '_')
      (solr_doc["#{prefix}_tag_ssim"] ||= []) << rest.strip
    end
    solr_doc
  end

  private

  # solrize each possible prefix for the tag, inclusive of the full tag.
  # e.g., for a tag such as "A : B : C", this will solrize to an _ssim field
  # that contains ["A",  "A : B",  "A : B : C"].
  def exploded_tags_from(tag)
    tag_parts = tag.split(TAG_PART_DELIMITER)

    1.upto(tag_parts.count).map do |i|
      tag_parts.take(i).join(TAG_PART_DELIMITER)
    end
  end

  def administrative_tags
    Dor::Services::Client.object(resource.pid).administrative_tags.list
  rescue Dor::Services::Client::NotFoundResponse
    []
  end
end
