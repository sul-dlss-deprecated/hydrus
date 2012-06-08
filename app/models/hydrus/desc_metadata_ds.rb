class Hydrus::DescMetadataDS < ActiveFedora::NokogiriDatastream

  include SolrDocHelper

  # MODS XML constants.

  MODS_NS = 'http://www.loc.gov/mods/v3'
  MODS_SCHEMA = 'http://www.loc.gov/standards/mods/v3/mods-3-3.xsd'
  MODS_PARAMS = {
    "version"            => "3.3", 
    "xmlns:xlink"        => "http://www.w3.org/1999/xlink",
    "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
    "xmlns"              => MODS_NS,
    "xsi:schemaLocation" => "#{MODS_NS} #{MODS_SCHEMA}",
  }

  # OM terminology.

  IA      = { :index_as => [:searchable, :displayable] }
  IAF     = { :index_as => [:searchable, :displayable, :facetable] }
  IANS    = { :index_as => [:not_searchable] }
  set_terminology do |t|
    t.root :path => 'mods', :xmlns => MODS_NS, :index_as => [:not_searchable]
    t.originInfo IANS do
      t.dateOther IA
    end
    t.abstract IA
    t.titleInfo IANS do
      t.title IA
    end
    t.title(
      :proxy => [:mods, :titleInfo, :title],
      :index_as => [:searchable, :displayable]
    )
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
      t.location IANS do
        t.url IA
      end
    end
    t.subject IANS do
      t.topic IAF
    end

    t.all_preferred_citation_notes :path => 'note',  :attributes => { :type => "preferred citation" }

    t.preferred_citation(
      :proxy => [:mods, :all_preferred_citation_notes],
      :index_as => [:searchable, :displayable]
    )
  end

  # Blocks to pass into Nokogiri::XML::Builder.new()

  def noko_builder_name
    return lambda { |xml| 
      xml.name {
        xml.namePart
        xml.role {
          xml.roleTerm(:authority => "marcrelator", :type => "text")
        }
      }
    }
  end

  def noko_builder_relatedItem
    return lambda { |xml| 
      xml.relatedItem {
        xml.titleInfo {
          xml.title
        }
        xml.location {
          xml.url
        }
      }
    }
  end

  def self.noko_builder_xml_template
    return lambda { |xml| 
      xml.mods(MODS_PARAMS) {
        xml.originInfo {
          xml.dateOther
        }
        xml.abstract
        xml.titleInfo {
          xml.title
        }
        xml.name {
          xml.namePart
          xml.role {
            xml.roleTerm
          }
        }
        xml.relatedItem {
          xml.titleInfo {
            xml.title
          }
          xml.location {
            xml.url
          }
        }
        xml.subject {
          xml.topic
        }
        xml.note(:type => "preferred citation")
      }
    }
  end

  # Methods returning empty XML documents and nodes.

  def self.xml_template
    return Nokogiri::XML::Builder.new(&send(:noko_builder_xml_template)).doc
  end
      
  def insert_person
    insert_new_node(:name)
  end
  
  def insert_related_item
    insert_new_node(:relatedItem)
  end

  def insert_new_node(term)
    builder = Nokogiri::XML::Builder.new(&send("noko_builder_#{term.to_s}"))
    node    = builder.doc.root
    nodeset = self.find_by_terms(term)
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

  def remove_node(term, index)
    node = self.find_by_terms(term.to_sym => index.to_i).first
    unless node.nil?
      node.remove
      self.dirty = true
    end
  end

end
