# frozen_string_literal: true

require 'spec_helper'

describe Hydrus::RightsMetadataDS, type: :model do
  before(:each) do
    xml = %Q(
      <rightsMetadata>
       <access type="discover"><machine><world/></machine></access>
       <access type="read"><machine/></access>
       <use><human type="useAndReproduction"/></use>
      </rightsMetadata>
    )
    @initial = noko_doc(xml)
    @doc = Hydrus::RightsMetadataDS.new(nil, nil)
  end

  it 'blank template should match our expectations' do
    expect(@doc.ng_xml).not_to be_nil
    expect(@initial   ).not_to be_nil
    expect(@doc.ng_xml).to be_equivalent_to(@initial)
  end

  it 'should be able to add and remove license (and not molest terms-of-use)' do
    # Initial: only a use-and-repro statement.
    ns = @doc.use.human.nodeset
    expect(ns.size).to eq(1)
    tou = ns.first
    expect(tou['type']).to eq('useAndReproduction')
    expect(@doc.use.machine).to eq([])
    # Insert a license.
    @doc.insert_license('GCODE', 'CODE', 'TXT')
    ns = @doc.use.human.nodeset
    expect(ns.size).to eq(2)
    tou = ns.first
    lic = ns.last
    expect(tou['type']).to eq('useAndReproduction')  # Still have tou.
    expect(lic['type']).to eq('GCODE')               # Check human license.
    expect(lic.content).to eq('TXT')
    ns = @doc.use.machine.nodeset # Check machine license.
    expect(ns.size).to eq(1)
    lic = ns.first
    expect(lic['type']).to eq('GCODE')
    expect(lic.content).to eq('CODE')
    # Remove license: back to initial conditions.
    @doc.remove_license
    ns = @doc.use.human.nodeset
    expect(ns.size).to eq(1)
    tou = ns.first
    expect(tou['type']).to eq('useAndReproduction')
    expect(@doc.use.machine).to eq([])
  end
end
