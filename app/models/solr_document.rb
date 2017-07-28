# -*- encoding : utf-8 -*-
# frozen_string_literal: true
class SolrDocument

  include Blacklight::Solr::Document

  # self.unique_key = 'id'

  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)
  field_semantics.merge!(
                         title: 'title_tesim',
                         author: 'author_display',
                         language: 'language_facet',
                         format: 'format'
                         )

  def route_key
    get('has_model_ssim').split(':').last.downcase.sub(/^dor_/, 'hydrus_')
  end

  def to_model
    @model ||= ActiveFedora::Base.load_instance_from_solr(id, self)
  end

  def main_title
    get('main_title_ssm')
  end

  def pid
    get('objectId_ssim')
  end

  def object_type
    get('has_model_ssim').gsub(/.+:Hydrus_/, '').downcase
  end

  def object_status
    typ    = object_type.to_sym
    status = get('object_status_ssim')
    Hydrus::GenericObject.status_label(typ, status)
  end

  def depositor
    get("#{object_type}_depositor_person_identifier_ssm")
  end

  def path
    "/#{object_type}s/#{pid}"
  end

end
