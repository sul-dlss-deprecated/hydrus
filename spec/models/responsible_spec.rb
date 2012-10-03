require 'spec_helper'

# A mock class to use while testing out mixin.
class MockResponsible

  include Hydrus::Responsible
  include Hydrus::ModelHelper

  attr_reader(:roleMetadata)

  def initialize
    @roleMetadata = Hydrus::RoleMetadataDS.from_xml(noko_doc(rmd_xml))
  end

  def rmd_xml
    return <<-EOF
      <roleMetadata>
        <role type="hydrus-collection-manager">
           <person>
              <identifier type="sunetid">brown</identifier>
              <name>Brown, Malcolm</name>
           </person>
           <person>
              <identifier type="sunetid">dblack</identifier>
              <name>Black, Delores</name>
           </person>
        </role>
        <role type="hydrus-collection-reviewer">
           <person>
              <identifier type="sunetid">ggreen</identifier>
              <name>Green, Greg</name>
           </person>
           <group>
              <identifier type="workgroup">pasig:2011attendees</identifier>
              <name>Conference attendees</name>
            </group>
        </role>
        <role type="hydrus-collection-item-depositor">
           <person>
              <identifier type="sunetid">bblue</identifier>
              <name>Blue, Bill</name>
           </person>
           <person>
              <identifier type="sunetid">ggreen</identifier>
              <name>Green, Greg</name>
           </person>
        </role>
      </roleMetadata>
    EOF
  end

end

describe Hydrus::Responsible do

  before(:each) do
    @obj = MockResponsible.new
    @orig_roles = {
      "hydrus-collection-manager"        => Set.new(["brown", "dblack"]),
      "hydrus-collection-reviewer"       => Set.new(["ggreen"]),
      "hydrus-collection-item-depositor" => Set.new(["bblue", "ggreen"]),
    }
  end

  it "person_roles() should return the expected hash" do
    @obj.person_roles.should == @orig_roles
  end

  it "persons_with_role() should return expected IDs" do
    @orig_roles.each do |role, ids|
      @obj.persons_with_role(role).should == ids
    end
  end

  it "roles_of_person() should return expected roles" do
    @obj.roles_of_person('ggreen').should == Set.new(%w(
      hydrus-collection-reviewer
      hydrus-collection-item-depositor
    ))
    @obj.roles_of_person('xxxxx').should == Set.new
  end

  it "person_roles= should rewrite the <person> nodes, but not <group> nodes" do
    exp = <<-EOF
      <roleMetadata>
        <role type="hydrus-collection-manager">
          <person>
            <identifier type="sunetid">archivist1</identifier>
            <name/>
          </person>
        </role>
        <role type="hydrus-collection-reviewer">
          <group>
            <identifier type="workgroup">pasig:2011attendees</identifier>
            <name>Conference attendees</name>
          </group>
          <person>
            <identifier type="sunetid">ggreen</identifier>
            <name/>
          </person>
        </role>
        <role type="hydrus-collection-item-depositor">
          <person>
            <identifier type="sunetid">foo</identifier>
            <name/>
          </person>
          <person>
            <identifier type="sunetid">bar</identifier>
            <name/>
          </person>
        </role>
      </roleMetadata>
    EOF
    @obj.person_roles= {
      "hydrus-collection-manager"  => "archivist1", 
      "hydrus-collection-reviewer" => "ggreen", 
      "hydrus-collection-item-depositor"      => "foo,bar",
    }
    @obj.roleMetadata.ng_xml.should be_equivalent_to(exp)
  end

  it "role_labels() should return the expect hash of roles and labels" do
    k1 = 'hydrus-item-depositor'
    k2 = 'hydrus-collection-reviewer'
    # Entire hash of hashes.
    h = Hydrus::Responsible.role_labels
    h[k1][:label].should == 'Item Depositor'
    h[k1][:help].should  =~ /original depositor/
    h[k2][:label].should == 'Reviewer'
    h[k2][:help].should  =~ /can review/
    # Just collection-level roles.
    Hydrus::Responsible.role_labels(:collection_level).keys.size.should == h.keys.size - 2
    # Just labels.
    h = Hydrus::Responsible.role_labels(:only_labels)
    h[k1].should == 'Item Depositor'
    h[k2].should == 'Reviewer'
    # Just help text.
    h = Hydrus::Responsible.role_labels(:only_help)
    h[k1].should  =~ /original depositor/
    h[k2].should  =~ /can review/
  end
  
end
