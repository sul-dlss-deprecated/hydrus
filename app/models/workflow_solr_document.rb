# frozen_string_literal: true

# Represents that part of the solr document that holds workflow data
class WorkflowSolrDocument
  WORKFLOW_SOLR = 'wf_ssim'
  # field that indexes workflow name, process status then process name
  WORKFLOW_WPS_SOLR = 'wf_wps_ssim'
  # field that indexes workflow name, process name then process status
  WORKFLOW_WSP_SOLR = 'wf_wsp_ssim'
  # field that indexes process status, workflowname then process name
  WORKFLOW_SWP_SOLR = 'wf_swp_ssim'
  WORKFLOW_ERROR_SOLR = 'wf_error_ssim'
  WORKFLOW_STATUS_SOLR = 'workflow_status_ssim'

  KEYS_TO_MERGE = [
    WORKFLOW_SOLR,
    WORKFLOW_WPS_SOLR,
    WORKFLOW_WSP_SOLR,
    WORKFLOW_SWP_SOLR,
    WORKFLOW_STATUS_SOLR,
    WORKFLOW_ERROR_SOLR
  ].freeze

  def initialize
    @data = empty_document
    yield self if block_given?
  end

  def name=(wf_name)
    data[WORKFLOW_SOLR] += [wf_name]
    data[WORKFLOW_WPS_SOLR] += [wf_name]
    data[WORKFLOW_WSP_SOLR] += [wf_name]
  end

  def status=(status)
    data[WORKFLOW_STATUS_SOLR] += [status]
  end

  def error=(message)
    data[WORKFLOW_ERROR_SOLR] += [message]
  end

  # Add to the field that indexes workflow name, process status then process name
  def add_wps(*messages)
    data[WORKFLOW_WPS_SOLR] += messages
  end

  # Add to the field that indexes workflow name, process name then process status
  def add_wsp(*messages)
    data[WORKFLOW_WSP_SOLR] += messages
  end

  # Add to the field that indexes process status, workflow name then process name
  def add_swp(*messages)
    data[WORKFLOW_SWP_SOLR] += messages
  end

  # Add the processes data_time attribute to the solr document
  # @param [String] wf_name
  # @param [String] process_name
  # @param [Time] time
  def add_process_time(wf_name, process_name, time)
    data["wf_#{wf_name}_#{process_name}_dttsi"] = time.utc.iso8601
  end

  def to_h
    KEYS_TO_MERGE.each { |k| data[k].uniq! }
    data
  end

  delegate :except, :[], to: :data

  # @param [WorkflowSolrDocument] doc
  def merge!(doc)
    # This is going to get the date fields, e.g. `wf_assemblyWF_jp2-create_dttsi'
    @data.merge!(doc.except(*KEYS_TO_MERGE))

    # Combine the non-unique fields together
    KEYS_TO_MERGE.each do |k|
      data[k] += doc[k]
    end
  end

  private

  attr_reader :data

  def empty_document
    KEYS_TO_MERGE.each_with_object({}) { |k, obj| obj[k] = [] }
  end
end
