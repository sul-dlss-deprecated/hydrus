class Hydrus::DescMetadataDS < ActiveFedora::NokogiriDatastream 

  include SolrDocHelper
  
  MODS_NS = 'http://www.loc.gov/mods/v3'

  set_terminology do |t|
    t.root :path => 'mods', :xmlns => MODS_NS, :index_as => [:not_searchable]

    t.originInfo :index_as => [:not_searchable] do
      t.publisher :index_as => [:searchable, :displayable]
      t.dateIssued
      t.place :index_as => [:not_searchable] do
        t.placeTerm :attributes => {:type => 'text'}, :index_as => [:searchable, :displayable]
      end
    end
    t.coordinates :index_as => [:searchable]
    t.extent      :index_as => [:searchable]
    t.scale       :index_as => [:searchable]
    t.topic       :index_as => [:searchable]
    t.abstract    :index_as => [:displayable]

    t.titleInfo :index_as => [:not_searchable] do
      t.title :index_as => [:searchable, :displayable]
    end
    t.title :proxy => [:mods, :titleInfo, :title]

    t.name do
      t.namePart
      t.role do
        t.roleTerm
      end
    end

    t.relatedItem do
      t.titleInfo do
        t.title
      end
      t.identifier(:attributes => { :type => "uri" })
    end

    t.subject do
      t.topic
    end

    t.preferred_citation :path => 'note', :attributes => { :type => "Preferred Citation" }
    t.peer_reviewed      :path => 'note', :attributes => { :type => "peer-review" }

  end

end
