require 'spec_helper'

# A mock class to use while testing out mixin.
class MockResponsible

  include Hydrus::Responsible

  attr_reader(:roleMetadata)

  def initialize
    @roleMetadata = Hydrus::RoleMetadataDS.from_xml(noko_doc(rmd_xml))
  end

  def rmd_xml
    return <<-EOF
      <roleMetadata>
        <role type="collection-manager">
           <person>
              <identifier type="sunetid">brown</identifier>
              <name>Brown, Malcolm</name>
           </person>
           <person>
              <identifier type="sunetid">dblack</identifier>
              <name>Black, Delores</name>
           </person>
        </role>
        <role type="collection-depositor">
           <person>
              <identifier type="sunetid">ggreen</identifier>
              <name>Green, Greg</name>
           </person>
           <group>
              <identifier type="workgroup">pasig:2011attendees</identifier>
              <name>Conference attendees</name>
            </group>
        </role>
      </roleMetadata>
    EOF
  end

end

describe Hydrus::Responsible do

  before(:each) do
    @obj = MockResponsible.new
  end

  it "person_roles() should return the expected hash" do
    @obj.person_roles.should == {
      "collection-manager"   => {"brown"=>true, "dblack"=>true},
      "collection-depositor" => {"ggreen"=>true},
    }
  end

  it "person_roles= should rewrite the <person> nodes, but not <group> nodes" do
    exp = <<-EOF
      <roleMetadata>
        <role type="collection-manager">
          <person>
            <identifier type="sunetid">archivist1</identifier>
            <name/>
          </person>
        </role>
        <role type="collection-depositor">
          <group>
            <identifier type="workgroup">pasig:2011attendees</identifier>
            <name>Conference attendees</name>
          </group>
        </role>
        <role type="item-depositor">
          <person>
            <identifier type="sunetid">foo</identifier>
            <name/>
          </person>
        </role>
      </roleMetadata>
    EOF
    @obj.person_roles= {
      "0" => {
        "id"   => "archivist1", 
        "role" => "collection-manager",
      },
      "1" => {
        "id"   => "foo",
        "role" => "item-depositor",
      },
    }
    @obj.roleMetadata.ng_xml.should be_equivalent_to(exp)
  end

end
