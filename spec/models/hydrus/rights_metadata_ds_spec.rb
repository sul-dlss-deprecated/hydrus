require 'spec_helper'

describe Hydrus::RightsMetadataDS do

  before(:each) do
    xml = %Q(
      <rightsMetadata>
       <access type="discover"><machine><world/></machine></access>
       <access type="read"><machine/></access>
       <access type="edit"><machine/></access>
       <use><human type="useAndReproduction"/></use>
      </rightsMetadata>
    )
    @initial = noko_doc(xml)
    @doc = Hydrus::RightsMetadataDS.new(nil, nil)
  end

  it "blank template should match our expectations" do
    @doc.ng_xml.should be_equivalent_to(@initial)
  end

  it "should be able to add and remove license (and not molest terms-of-use)" do
    # Initial: only a use-and-repro statement.
    ns = @doc.use.human.nodeset
    ns.size.should == 1
    tou = ns.first
    tou['type'].should == 'useAndReproduction'
    @doc.use.machine.should == []
    # Insert a license.
    @doc.insert_license('GCODE', 'CODE', 'TXT')
    ns = @doc.use.human.nodeset
    ns.size.should == 2
    tou = ns.first
    lic = ns.last
    tou['type'].should == 'useAndReproduction'  # Still have tou.
    lic['type'].should == 'GCODE'               # Check human license.
    lic.content.should == 'TXT'
    ns = @doc.use.machine.nodeset               # Check machine license.
    ns.size.should == 1
    lic = ns.first
    lic['type'].should == 'GCODE'
    lic.content.should == 'CODE'
    # Remove license: back to initial conditions.
    @doc.remove_license
    ns = @doc.use.human.nodeset
    ns.size.should == 1
    tou = ns.first
    tou['type'].should == 'useAndReproduction'
    @doc.use.machine.should == []
  end

end
