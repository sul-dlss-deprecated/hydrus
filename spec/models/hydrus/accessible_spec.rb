# frozen_string_literal: true
require 'spec_helper'

# A mock class to use while testing the mixin.
class MockAccessible

  include Hydrus::Accessible

  attr_reader(:embargoMetadata, :rightsMetadata)

  def initialize(emd, rmd)
    @embargoMetadata = Dor::EmbargoMetadataDS.from_xml(emd)
    @rightsMetadata  = Hydrus::RightsMetadataDS.from_xml(rmd)
  end

end

describe Hydrus::Accessible, type: :model do
  before(:each) do
    # XML snippets for various <access> nodes.
    @emb_date = 99999999
    mw        = '<machine><world/></machine>'
    ms        = '<machine><group>stanford</group></machine>'
    embe      = "<releaseDate>#{@emb_date}</releaseDate>"
    embr      = "<machine><embargoReleaseDate>#{@emb_date}</embargoReleaseDate></machine>"
    rd_world  = %Q[<access type="read">#{mw}</access>]
    rd_stanf  = %Q[<access type="read">#{ms}</access>]
    rd_embr   = %Q[<access type="read">#{embr}</access>]
    rd_blank  = %Q[<access type="read"><machine/></access>]
    di_world  = %Q[<access type="discover">#{mw}</access>]
    # XML snippets for embargoMetadata.
    em_start  = %Q[<embargoMetadata><status/><releaseDate/>]
    em_end    = %Q[</embargoMetadata>]
    em_blank  = %Q[<releaseAccess/>]
    em_world  = %Q[<releaseAccess>#{di_world}#{rd_world}</releaseAccess>]
    em_stanf  = %Q[<releaseAccess>#{di_world}#{rd_stanf}</releaseAccess>]
    # XML snippets for rightsMetadata.
    rm_start  = %Q[<rightsMetadata>]
    rm_end    = '<use><human/><machine/></use></rightsMetadata>'
    # Assemble Nokogiri XML for embargoMetadata and rightsMetadata.
    @xml = {
      em_initial: noko_doc([em_start, em_blank, em_end].join),
      em_world: noko_doc([em_start, em_world, em_end].join),
      em_stanf: noko_doc([em_start, em_stanf, em_end].join),
      em_embargo: noko_doc([em_start, embe,     em_end].join),
      rm_initial: noko_doc([rm_start, di_world, rd_blank, rm_end].join),
      rm_world: noko_doc([rm_start, di_world, rd_world, rm_end].join),
      rm_stanf: noko_doc([rm_start, di_world, rd_stanf, rm_end].join),
      rm_embargo: noko_doc([rm_start, di_world, rd_embr,  rm_end].join),
    }
  end

  it 'has_world_read_node() and world_read_nodes()' do
    # World readable: yes.
    obj = MockAccessible.new(@xml[:em_initial], @xml[:rm_initial])
    expect(obj.embargoMetadata.has_world_read_node).to eq(false)
    expect(obj.rightsMetadata.has_world_read_node).to  eq(false)
    # World readable: no.
    obj = MockAccessible.new(@xml[:em_world], @xml[:rm_world])
    [obj.embargoMetadata, obj.rightsMetadata].each do |ds|
      expect(ds.has_world_read_node).to eq(true)
      expect(ds.world_read_nodes.size).to eq(1)
    end
  end

  it 'group_read_nodes()' do
    obj = MockAccessible.new(@xml[:em_stanf], @xml[:rm_stanf])
    [obj.embargoMetadata, obj.rightsMetadata].each do |ds|
      ns = ds.group_read_nodes
      expect(ns.size).to eq(1)
      expect(ns.first.content).to eq('stanford')
    end
  end

  it 'remove_world_read_access()' do
    obj = MockAccessible.new(@xml[:em_world], @xml[:rm_world])
    [obj.embargoMetadata, obj.rightsMetadata].each do |ds|
      expect(ds.has_world_read_node).to eq(true)
      ds.remove_world_read_access()
      expect(ds.has_world_read_node).to eq(false)
    end
  end

  it 'remove_group_read_nodes() and add_read_group()' do
    obj = MockAccessible.new(@xml[:em_stanf], @xml[:rm_stanf])
    [obj.embargoMetadata, obj.rightsMetadata].each do |ds|
      expect(ds.group_read_nodes.size).to eq(1)
      ds.remove_group_read_nodes()
      expect(ds.group_read_nodes.size).to eq(0)
      ds.add_read_group('stanford')
      ds.add_read_group('foo')
      expect(ds.group_read_nodes.size).to eq(2)
      ds.remove_group_read_nodes()
      expect(ds.group_read_nodes.size).to eq(0)
    end
  end

  it 'make_world_readable()' do
    obj = MockAccessible.new(@xml[:em_stanf], @xml[:rm_stanf])
    [obj.embargoMetadata, obj.rightsMetadata].each do |ds|
      expect(ds.group_read_nodes.size).to eq(1)
      expect(ds.has_world_read_node).to eq(false)
      ds.make_world_readable()
      expect(ds.group_read_nodes.size).to eq(0)
      expect(ds.has_world_read_node).to eq(true)
    end
  end

  it 'remove_embargo_date()' do
    obj = MockAccessible.new(@xml[:em_embargo], @xml[:rm_embargo])
    [obj.embargoMetadata, obj.rightsMetadata].each do |ds|
      expect(ds.ng_xml.to_s).to match(/#{@emb_date}/)
      ds.remove_embargo_date()
      expect(ds.ng_xml.to_s).not_to match(/#{@emb_date}/)
    end
  end

  it 'update_access_blocks(world)' do
    obj = MockAccessible.new(@xml[:em_stanf], @xml[:rm_stanf])
    [obj.embargoMetadata, obj.rightsMetadata].each do |ds|
      expect(ds.has_world_read_node).to eq(false)
      expect(ds.group_read_nodes.size).to eq(1)
      ds.update_access_blocks('world')
      expect(ds.group_read_nodes.size).to eq(0)
      expect(ds.has_world_read_node).to eq(true)
    end
  end

  it 'update_access_blocks(stanford)' do
    obj = MockAccessible.new(@xml[:em_world], @xml[:rm_world])
    [obj.embargoMetadata, obj.rightsMetadata].each do |ds|
      expect(ds.has_world_read_node).to eq(true)
      expect(ds.group_read_nodes.size).to eq(0)
      ds.update_access_blocks('stanford')
      expect(ds.group_read_nodes.size).to eq(1)
      expect(ds.has_world_read_node).to eq(false)
    end
  end

  it 'initialize_release_access_node()' do
    obj0 = MockAccessible.new(@xml[:em_initial], @xml[:rm_initial])
    obj1 = MockAccessible.new(@xml[:em_initial], @xml[:rm_initial])
    obj2 = MockAccessible.new(@xml[:em_stanf],   @xml[:rm_stanf])
    obj2.embargoMetadata.remove_group_read_nodes()
    ds1 = obj1.embargoMetadata
    ds2 = obj2.embargoMetadata
    # From initial to generic: should look like em_stanf minue the group nodes.
    ds1.initialize_release_access_node(:generic)
    expect(ds1.ng_xml).to be_equivalent_to(ds2.ng_xml)
    # From generic to blank: should look like em_initial.
    ds1.initialize_release_access_node()
    expect(ds1.ng_xml).to be_equivalent_to(obj0.embargoMetadata.ng_xml)
  end
end
