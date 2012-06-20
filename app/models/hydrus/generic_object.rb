class Hydrus::GenericObject < Dor::Item

  attr_accessor :publish
  
  include ActiveModel::Validations
  validates :title, :abstract, :not_empty => true, :if => :clicked_publish?
  
  validates :pid, :is_druid=>true
  
  attr_accessor :apo_pid

  has_metadata(
    :name => "descMetadata",
    :type => Hydrus::DescMetadataDS,
    :label => 'Descriptive Metadata',
    :control_group => 'M')

  def object_type
      identityMetadata.objectType.first
  end
  
  def clicked_publish?
    publish == "true"
  end
  
  delegate :abstract, :to => "descMetadata"  
  delegate :title, :to => "descMetadata"
  delegate :related_item_title, :to => "descMetadata", :at => [:relatedItem, :titleInfo, :title]
  delegate :related_item_url, :to => "descMetadata", :at => [:relatedItem, :location, :url]
    
  def apo
    @apo ||= (apo_pid ? get_fedora_item(apo_pid) : nil)
  end

  def apo_pid
    @apo_pid ||= admin_policy_object_ids.first
  end

  def get_fedora_item(pid)
    return ActiveFedora::Base.find(pid, :cast => true)
  end

  def discover_access
    return rightsMetadata.discover_access.first
  end

   def url
     "http://purl.stanford.edu/#{pid}"
   end

  def related_items
    @related_items ||= descMetadata.find_by_terms(:relatedItem).map { |n|
      Hydrus::RelatedItem.new_from_node(n)
    }
  end
  
end
