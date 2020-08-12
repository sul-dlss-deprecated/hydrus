# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

RSpec.describe WorkflowIndexer do
  before do
    stub_request(:get, 'https://localhost/workflow_templates/accessionWF')
      .to_return(status: 200, body: workflow_template_json)
  end

  let(:document) { Dor::Workflow::Response::Workflow.new(xml: xml) }
  let(:indexer) { described_class.new(workflow: document) }

  let(:workflow_template_json) do
    '{"processes":[{"name":"hello"},{"name":"goodbye"},{"name":"technical-metadata"},{"name":"some-other-step"}]}'
  end

  let(:step1) { 'hello' }
  let(:step2) { 'goodbye' }
  let(:step3) { 'technical-metadata' }
  let(:step4) { 'some-other-step' }

  describe '#to_solr' do
    subject(:solr_doc) { indexer.to_solr.to_h }

    context 'when not all of the steps are completed' do
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workflow objectId="druid:gv054hp4128" id="accessionWF">
          <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="waiting" name="technical-metadata"/>
        </workflow>
        XML
      end

      it 'creates the workflow_status field with the workflow repository included, and indicates that the workflow is still active' do
        expect(solr_doc[Solrizer.solr_name('workflow_status', :symbol)].first).to eq('accessionWF|active|0')
      end
    end

    context 'when the template has been changed to have new steps, but the workflow service indicates all steps are completed' do
      let(:workflow_template_json) do
        '{"processes":[{"name":"hello"},{"name":"goodbye"},{"name":"technical-metadata"},{"name":"some-other-step"}]}'
      end

      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workflow objectId="druid:gv054hp4128" id="accessionWF">
          <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="completed" name="technical-metadata"/>
        </workflow>
        XML
      end

      it 'indicates that the workflow is complete' do
        expect(solr_doc[Solrizer.solr_name('workflow_status', :symbol)].first).to eq('accessionWF|completed|0')
      end
    end

    context 'when all steps are completed or skipped' do
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workflow objectId="druid:gv054hp4128" id="accessionWF">
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="skipped" name="hello"/>
          <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:24-0800" status="completed" name="some-other-step"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="completed" name="technical-metadata"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="skipped" name="goodbye"/>
        </workflow>
        XML
      end

      it 'indexes the right workflow status (completed)' do
        expect(solr_doc).to match a_hash_including('workflow_status_ssim' => ['accessionWF|completed|0'])
      end
    end

    context 'when the xml has dates for completed and errored steps' do
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workflow objectId="druid:gv054hp4128" id="accessionWF">
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:57-0800" status="error" name="hello"/>
          <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="completed" name="technical-metadata"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="" name="goodbye"/>
        </workflow>
        XML
      end

      it 'indexes the iso8601 UTC dates' do
        expect(solr_doc).to match a_hash_including('wf_accessionWF_hello_dttsi' => '2012-11-07T00:18:57Z')
        expect(solr_doc).to match a_hash_including('wf_accessionWF_technical-metadata_dttsi' => '2012-11-07T00:18:58Z')
      end
    end

    context 'when the xml does not have dates for completed and errored steps' do
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workflow objectId="druid:gv054hp4128" id="accessionWF">
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="" status="error" name="hello"/>
          <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="completed" name="technical-metadata"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="" name="goodbye"/>
        </workflow>
        XML
      end

      it 'only indexes the dates on steps that include a date' do
        expect(solr_doc).to match a_hash_including('wf_accessionWF_technical-metadata_dttsi')
        expect(solr_doc).not_to match a_hash_including('wf_accessionWF_hello_dttsi')
        expect(solr_doc).not_to match a_hash_including('wf_accessionWF_start-accession_dttsi')
        expect(solr_doc).not_to match a_hash_including('wf_accessionWF_goodbye_dttsi')
      end
    end

    context 'when there are error messages' do
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workflow objectId="druid:gv054hp4128" id="accessionWF">
          <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="error" errorMessage="druid:gv054hp4128 - Item error; caused by 413 Request Entity Too Large:" name="technical-metadata"/>
        </workflow>
        XML
      end

      let(:wf_error) { solr_doc[Solrizer.solr_name('wf_error', :symbol)] }

      it 'indexes the error messages' do
        expect(wf_error).to eq ['accessionWF:technical-metadata:druid:gv054hp4128 - Item error; caused by 413 Request Entity Too Large:']
      end
    end

    context 'when the error messages are crazy long' do
      let(:error_length) { 40_000 }
      let(:error) { (0...error_length).map { rand(65..90).chr }.join }
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <workflow objectId="druid:gv054hp4128" id="accessionWF">
          <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
          <process version="2" elapsed="0.0" archived="true" attempts="1"
           datetime="2012-11-06T16:18:58-0800" status="error" errorMessage="#{error}" name="technical-metadata"/>
        </workflow>
        XML
      end

      let(:wf_error) { solr_doc[Solrizer.solr_name('wf_error', :symbol)] }

      it "truncates the error messages to below Solr's limit" do
        # 31 is the leader
        expect(wf_error.first.length).to be < 32_766
      end
    end
  end
end
