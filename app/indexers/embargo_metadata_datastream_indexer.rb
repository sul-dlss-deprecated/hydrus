# frozen_string_literal: true

class EmbargoMetadataDatastreamIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  # @return [Hash] the partial solr document for embargoMetadata
  def to_solr
    {
      'embargo_status_ssim' => embargo_status,
      'twenty_pct_status_ssim' => Array(twenty_pct_status)
    }.tap do |solr_doc|
      rd20 = twenty_pct_release_date
      solr_doc['embargo_release_dtsim'] = Array(release_date.first.utc.strftime('%FT%TZ')) if release_date.first.present?
      solr_doc['twenty_pct_release_embargo_release_dtsim'] = Array(rd20.utc.strftime('%FT%TZ')) if rd20.present?
    end
  end

  # rubocop:disable Lint/UselessAccessModifier
  private

  # rubocop:enable Lint/UselessAccessModifier

  delegate :embargoMetadata, to: :resource
  delegate :embargo_status, :twenty_pct_status, :twenty_pct_release_date, :release_date, to: :embargoMetadata
end
