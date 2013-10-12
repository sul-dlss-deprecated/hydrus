# -*- encoding : utf-8 -*-
class SolrDocument

  include Blacklight::Solr::Document

  # self.unique_key = 'id'

  def route_key
    models = Array(get(Solrizer.solr_name('has_model', :symbol), :sep => nil))
    route_key = models.select { |x| x =~ /Hydrus/ }.first
    route_key ||= models.select { |x| x =~ /Dor/ }.first.gsub("Dor_", "Hydrus_")
    route_key.split(':').last.downcase
  end

  def to_model
    @model ||= ActiveFedora::Base.load_instance_from_solr(id, self)
  end

  def main_title
    return get('main_title_t')
  end

  def pid
    return get('identityMetadata_objectId_t')
  end

  def object_type
    route_key.gsub("hydrus_", "")
  end

  def object_status
    typ    = object_type.to_sym
    status = get('object_status_t')
    return Hydrus::GenericObject.status_label(typ, status)
  end

  def depositor
    return get("roleMetadata_#{object_type}_depositor_person_identifier_t")
  end

  def path
    return "/#{object_type}s/#{pid}"
  end

end
