require 'spec_helper'

describe Hydrus::RoleMetadataDS do

  before(:all) do
    @rmd_start = '<roleMetadata>'
    @rmd_end   = '</roleMetadata>'
  end

  before(:each) do
    xml = <<-EOF
      #{@rmd_start}
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
        <role type="collection-reviewer">
           <group>
              <identifier type="workgroup">pasig:staff</identifier>
              <name>Conference attendees</name>
           </group>
        </role>
        <role type="collection-viewer">
           <group>
              <identifier type="community">stanford</identifier>
              <name>Stanford University Community</name>
           </group>
        </role>
      #{@rmd_end}
    EOF
    @rmdoc = Hydrus::RoleMetadataDS.from_xml(xml)
  end
  
  it "should get expected values from OM terminology" do
    tests = [
      [[:role, :person, :identifier], %w(brown dblack ggreen)],
      [[:role, :group,  :identifier], %w(pasig:2011attendees pasig:staff stanford)],
      [[:role, :person, :name], ["Brown, Malcolm", "Black, Delores", "Green, Greg"]],
      [[:collection_manager, :person, :identifier], %w(brown dblack)],
      [[:collection_manager, :group, :identifier], %w()],
      [[:collection_depositor, :person, :identifier], %w(ggreen)],
      [[:collection_depositor, :group, :identifier], %w(pasig:2011attendees)],
      [[:collection_reviewer, :person, :identifier], %w()],
      [[:collection_reviewer, :group, :identifier], %w(pasig:staff)],
      [[:collection_viewer, :person, :identifier], %w()],
      [[:collection_viewer, :group, :identifier], %w(stanford)],
      [[:role, :type], %w(collection-manager collection-depositor collection-reviewer collection-viewer)],
      [[:person, :identifier, :type], %w(sunetid sunetid sunetid)],
      [[:group, :identifier, :type], %w(workgroup workgroup community)],
      [[:actor], %w()],
    ]
    tests.each do |terms, exp|
      @rmdoc.term_values(*terms).should == exp
    end
  end

  it "Should be able to insert new role, person, and group nodes" do
    p = '<person><identifier type="sunetid"/><name/></person>'
    gs = '<group><identifier type="stanford"/><name/></group>'
    gw = '<group><identifier type="workgroup"/><name/></group>'
    exp_parts = [
      @rmd_start,
      '<role type="collection-manager">',  gw, p,     '</role>',
      '<role type="collection-reviewer">', gs, p, gs, '</role>',
      @rmd_end,
    ]
    @exp_xml = noko_doc(exp_parts.join '')
    @rmdoc   = Hydrus::RoleMetadataDS.from_xml("#{@rmd_start}#{@rmd_end}")
    role_node1 = @rmdoc.insert_role('collection_manager')
    role_node2 = @rmdoc.insert_role('collection_reviewer')
    @rmdoc.insert_group(role_node2, 'stanford')
    @rmdoc.insert_person(role_node2)
    @rmdoc.insert_group(role_node1, 'workgroup')
    @rmdoc.insert_person(role_node1)
    @rmdoc.insert_group(role_node2, 'stanford')
    @rmdoc.ng_xml.should be_equivalent_to @exp_xml
  end

  it "the blank template should match our expectations" do
    exp_xml = %Q(
      #{@rmd_start}
      #{@rmd_end}
    )
    exp_xml = noko_doc(exp_xml)
    @rmdoc = Hydrus::RoleMetadataDS.new(nil, nil)
    @rmdoc.ng_xml.should be_equivalent_to exp_xml
  end

  it "should be able to exercise to_solr()" do
    sdoc = @rmdoc.to_solr
    sdoc.should be_kind_of Hash
    exp_hash = {
      "apo_register_permissions_t"                => ["sunetid:brown", "sunetid:dblack", "sunetid:ggreen", "workgroup:pasig:2011attendees"],
      "apo_role_collection_depositor_facet"       => ["sunetid:ggreen", "workgroup:pasig:2011attendees"],
      "apo_role_collection_depositor_t"           => ["sunetid:ggreen", "workgroup:pasig:2011attendees"],
      "apo_role_group_collection_depositor_facet" => ["workgroup:pasig:2011attendees"],
      "apo_role_group_collection_depositor_t"     => ["workgroup:pasig:2011attendees"],
      "apo_role_person_collection_manager_facet"  => ["sunetid:brown", "sunetid:dblack"],
      "apo_role_person_collection_manager_t"      => ["sunetid:brown", "sunetid:dblack"],
    }
    sdoc.should include(exp_hash)
  end

end
