# frozen_string_literal: true

# Indexes the process for a workflow
class ProcessIndexer
  ERROR_OMISSION = '... (continued)'
  private_constant :ERROR_OMISSION

  # see https://lucene.apache.org/core/7_3_1/core/org/apache/lucene/util/BytesRefHash.MaxBytesLengthExceededException.html
  MAX_ERROR_LENGTH = 32_768 - 2 - ERROR_OMISSION.length
  private_constant :MAX_ERROR_LENGTH

  # @param [WorkflowSolrDocument] solr_doc
  # @param [String] workflow_name
  # @param [Dor::Workflow::Response::Process] process
  def initialize(solr_doc:, workflow_name:, process:)
    @solr_doc = solr_doc
    @workflow_name = workflow_name
    @process = process
  end

  # @return [Hash] the partial solr document for the workflow document
  def to_solr
    return unless status

    # add a record of the robot having operated on this item, so we can track robot activity
    solr_doc.add_process_time(workflow_name, name, Time.parse(process.datetime)) if has_time?

    index_error_message

    # workflow name, process status then process name
    solr_doc.add_wsp("#{workflow_name}:#{status}", "#{workflow_name}:#{status}:#{name}")

    # workflow name, process name then process status
    solr_doc.add_wps("#{workflow_name}:#{name}", "#{workflow_name}:#{name}:#{status}")

    # process status, workflowname then process name
    solr_doc.add_swp(process.status.to_s, "#{status}:#{workflow_name}", "#{status}:#{workflow_name}:#{name}")
  end

  private

  attr_reader :process, :workflow_name, :solr_doc
  delegate :status, :name, :state, :error_message, :datetime, to: :process

  def has_time?
    datetime && (status == 'completed' || status == 'error')
  end

  # index the error message without the druid so we hopefully get some overlap
  # truncate to avoid org.apache.lucene.util.BytesRefHash$MaxBytesLengthExceededException
  def index_error_message
    return unless error_message

    solr_doc.error = "#{workflow_name}:#{name}:#{error_message}".truncate(MAX_ERROR_LENGTH, omission: ERROR_OMISSION)
  end
end
