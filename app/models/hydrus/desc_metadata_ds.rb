class Hydrus::DescMetadataDS < ActiveFedora::NokogiriDatastream

  include SolrDocHelper
  include Hydrus::GenericDS

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

    t.titleInfo IANS do
      t.title IA
    end
    t.name IANS do
      t.namePart IAF
      t.role IANS do
        t.roleTerm IA
      end
    end
    t.abstract IA
    t.preferred_citation :path => 'note',  :attributes => { :type => "preferred citation" }
    t.related_citation   :path => 'note',  :attributes => { :type => "citation/reference" }
    t.contact            :path => 'note',  :attributes => { :type => "contact" }
    t.subject IANS do
      t.topic IAF
    end
    t.relatedItem IANS do
      t.titleInfo IANS do
        t.title IA
      end
      t.location IANS do
        t.url IA
      end
    end

    t.main_title(
      :proxy => [:mods, :titleInfo, :title],
      :index_as => [:searchable, :displayable]
    )

  end

  # Blocks to pass into Nokogiri::XML::Builder.new()

  define_template :name do |xml|
    xml.name {
      xml.namePart
      xml.role {
        xml.roleTerm(:authority => "marcrelator", :type => "text")
      }
    }
  end

  define_template :relatedItem do |xml|
    xml.relatedItem {
      xml.titleInfo {
        xml.title
      }
      xml.location {
        xml.url
      }
    }
  end

  define_template :related_citation do |xml|
    xml.note(:type => "citation/reference", :displayLabel => 'Related Publication')
  end

  define_template :topic do |xml, topic|
    xml.subject {
      xml.topic(topic)
    }
  end

  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.mods(MODS_PARAMS) {
        xml.titleInfo {
          xml.title
        }
        xml.abstract
        xml.note(:type => "preferred citation", :displayLabel => 'Preferred Citation')
        xml.note(:type => "citation/reference", :displayLabel => 'Related Publication')
        xml.note(:type => "contact",            :displayLabel => 'Contact')
        xml.subject {
          xml.topic
        }
        xml.relatedItem {
          xml.titleInfo {
            xml.title
          }
          xml.location {
            xml.url
          }
        }
      }
    end.doc
  end

  def insert_person
    add_hydrus_next_sibling_node(:name, :name)
  end

  def insert_related_item
    add_hydrus_next_sibling_node(:relatedItem, :relatedItem)
  end

  def insert_related_citation
    add_hydrus_next_sibling_node(:related_citation, :related_citation)
  end

  def insert_topic(topic)
    add_hydrus_next_sibling_node(:subject, :topic, topic)
  end

end
