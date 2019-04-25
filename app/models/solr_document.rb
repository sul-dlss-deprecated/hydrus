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

  # given a solr document, try a few places to get the title, starting with objectlabel, then dc_title, and finally just untitled
  def object_title
    mods_title = self['titleInfo_title_ssm'].reject(&:blank?)
    dc_title = self['title_tesim']

    return mods_title.first if mods_title.present?

    return dc_title.first if dc_title && dc_title.first != 'Hydrus'

    'Untitled'
  end

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
