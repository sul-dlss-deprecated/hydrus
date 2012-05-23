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

end
