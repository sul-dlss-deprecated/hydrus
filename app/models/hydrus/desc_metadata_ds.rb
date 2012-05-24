class Hydrus::DescMetadataDS < ActiveFedora::NokogiriDatastream

  include SolrDocHelper

  MODS_NS = 'http://www.loc.gov/mods/v3'
  IA      = { :index_as => [:searchable, :displayable] }
  IAF     = { :index_as => [:searchable, :displayable, :facetable] }
  IANS    = { :index_as => [:not_searchable] }

  set_terminology do |t|
    t.root :path => 'mods', :xmlns => MODS_NS, :index_as => [:not_searchable]

    t.originInfo IANS do
      t.publisher  IA
      t.dateIssued IA
    end
    t.abstract IA

    t.titleInfo IANS do
      t.title IA
    end
    t.title(:proxy => [:mods, :titleInfo, :title],
            :index_as => [:searchable, :displayable])

    t.name IANS do
      t.namePart IAF
      t.role IANS do
        t.roleTerm IA
      end
    end

    t.relatedItem IANS do
      t.titleInfo IANS do
        t.title IA
      end
      t.identifier(:attributes => { :type => "uri" },
                   :index_as => [:searchable, :displayable])
    end

    t.subject IANS do
      t.topic IAF
    end

    t.preferred_citation(:path => 'note',
                         :attributes => { :type => "Preferred Citation" },
                         :index_as => [:searchable, :displayable])

    t.peer_reviewed(:path => 'note',
                    :attributes => { :type => "peer-review" },
                    :index_as => [:searchable, :displayable])

  end
  
  def insert_person
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.name {
        xml.namePart
        xml.role {
          xml.roleTerm(:authority=>"marcrelator", :type=>"text")
        }                          
      }
    end
    node = builder.doc.root
    nodeset = self.find_by_terms(:name)
    
    unless nodeset.nil?
      if nodeset.empty?
        self.ng_xml.root.add_child(node)
        index = 0
      else
        nodeset.after(node)
        index = nodeset.length
      end
      self.dirty = true
    end
    
    return node, index
  end
  
  def insert_related_item
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.relatedItem {
        xml.titleInfo {
          xml.title
        }
        xml.identifier(:type=>"uri")
      }
    end
    node = builder.doc.root
    nodeset = self.find_by_terms(:relatedItem)
    
    unless nodeset.nil?
      if nodeset.empty?
        self.ng_xml.root.add_child(node)
        index = 0
      else
        nodeset.after(node)
        index = nodeset.length
      end
      self.dirty = true
    end
    
    return node, index
  end
  
end
