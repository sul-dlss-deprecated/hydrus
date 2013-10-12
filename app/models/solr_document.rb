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
    return get(Solrizer.solr_name('main_title', :displayable))
  end

  def collection_title
    first(Solrizer.solr_name('hydrus_collection_title', :displayable))
  end

  def collection_id
    pid = first(Solrizer.solr_name('is_member_of_collection', :symbol)) || ''

    pid.gsub('info:fedora/', '')
  end

  def pid
    return get(Solrizer.solr_name('objectId', :symbol))
  end

  def object_type
    route_key.gsub("hydrus_", "")
  end

  def object_status
    typ    = object_type.to_sym
    status = get(Solrizer.solr_name('object_status', :displayable))
    return Hydrus::GenericObject.status_label(typ, status)
  end

  def depositor
    return get(Solrizer.solr_name("#{object_type}_depositor_person_identifier", :displayable))
  end

  def path
    return "/#{object_type}s/#{pid}"
  end

end
