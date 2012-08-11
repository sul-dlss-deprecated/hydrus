class Hydrus::EventsDS < ActiveFedora::NokogiriDatastream

  include Hydrus::GenericDS
  
  set_terminology do |t|
    t.root :path => 'events'
    t.event {
      t.type_ :path => {:attribute => 'type'}
      t.who   :path => {:attribute => 'who'}
      t.when  :path => {:attribute => 'when'}
    }
  end

  def add(event_text, opts = {})
    opts = {:type => 'hydrus', :who => 'UNKNOWN_USER', :when => Time.now}.merge(opts)
    add_hydrus_child_node(ng_xml.root, :event, event_text, opts)
  end

  # OM templates.

  define_template(:event) do |xml, event_text, opts|
    xml.event(event_text, opts)
  end

  # Empty XML document.
  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.events
    end.doc
  end

end
