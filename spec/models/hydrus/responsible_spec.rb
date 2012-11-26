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
              <identifier type="sunetid">archivist4</identifier>
              <name>Archivist, Four</name>
           </person>
           <person>
              <identifier type="sunetid">archivist5</identifier>
              <name>Archivist, Five</name>
           </person>
        </role>
        <role type="hydrus-collection-reviewer">
           <person>
              <identifier type="sunetid">archivist3</identifier>
              <name>Archivist, Three</name>
           </person>
           <group>
              <identifier type="workgroup">pasig:2011attendees</identifier>
              <name>Conference attendees</name>
            </group>
        </role>
        <role type="hydrus-collection-item-depositor">
           <person>
              <identifier type="sunetid">archivist6</identifier>
              <name>Archivist, Six</name>
           </person>
           <person>
              <identifier type="sunetid">archivist3</identifier>
              <name>Archivist, Three</name>
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
      "hydrus-collection-manager"        => Set.new(["archivist4", "archivist5"]),
      "hydrus-collection-reviewer"       => Set.new(["archivist3"]),
      "hydrus-collection-item-depositor" => Set.new(["archivist6", "archivist3"]),
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
    @obj.roles_of_person('archivist3').should == Set.new(%w(
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
          <person>
            <identifier type="sunetid">ZZZ</identifier>
            <name/>
          </person>
        </role>
        <role type="hydrus-collection-reviewer">
          <group>
            <identifier type="workgroup">pasig:2011attendees</identifier>
            <name>Conference attendees</name>
          </group>
          <person>
            <identifier type="sunetid">archivist3</identifier>
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
      "hydrus-collection-manager"        => "archivist1,ZZZ",
      "hydrus-collection-reviewer"       => "archivist3,ZZZ",
      "hydrus-collection-item-depositor" => "foo,bar,ZZZ",
    }
    @obj.roleMetadata.ng_xml.should be_equivalent_to(exp)
  end

  it "pruned_role_info() should prune out lesser roles" do
    h = {
      'hydrus-collection-depositor'      => 'aaa',
      'hydrus-collection-manager'        => 'aaa,bbb,ccc,ddd,eee',
      'hydrus-collection-reviewer'       => 'bbb,ccc,xxx,yyy',
      'hydrus-collection-item-depositor' => 'ccc,ddd,xxx,zzz',
      'hydrus-collection-viewer'         => 'aaa,bbb,ccc,QQQ,RRR',
    }
    exp = {
      'aaa' => Set.new(%w(hydrus-collection-depositor hydrus-collection-manager)),
      'bbb' => Set.new(%w(hydrus-collection-manager)),
      'ccc' => Set.new(%w(hydrus-collection-manager)),
      'ddd' => Set.new(%w(hydrus-collection-manager)),
      'eee' => Set.new(%w(hydrus-collection-manager)),
      'xxx' => Set.new(%w(hydrus-collection-reviewer hydrus-collection-item-depositor)),
      'yyy' => Set.new(%w(hydrus-collection-reviewer)),
      'zzz' => Set.new(%w(hydrus-collection-item-depositor)),
      'QQQ' => Set.new(%w(hydrus-collection-viewer)),
      'RRR' => Set.new(%w(hydrus-collection-viewer)),
    }
    Hydrus::Responsible.pruned_role_info(h).should == exp
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
    h[k2][:lesser].should == %w(hydrus-collection-viewer)
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
