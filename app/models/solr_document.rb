# -*- encoding : utf-8 -*-

class SolrDocument
  include Blacklight::Solr::Document

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
  field_semantics.merge!(
    title: 'title_tesim',
    author: 'author_display',
    language: 'language_facet',
    format: 'format'
  )

  def route_key
    first('has_model_ssim').split(':').last.downcase.sub(/^dor_/, 'hydrus_')
  end

  def to_model
    @model ||= ActiveFedora::Base.load_instance_from_solr(id, self)
  end

  def main_title
    first('main_title_ssm')
  end

  def pid
    first('objectId_ssim')
  end

  def object_type
    first('has_model_ssim').gsub(/.+:Hydrus_/, '').downcase
  end

  def object_status
    typ    = object_type.to_sym
    status = first('object_status_ssim')
    Hydrus::GenericObject.status_label(typ, status)
  end

  def depositor
    self["#{object_type}_depositor_person_identifier_ssm"]
  end

  def path
    "/#{object_type}s/#{pid}"
  end
end
