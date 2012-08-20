require 'spec_helper'

describe Hydrus::RoleMetadataDS do

  before(:all) do
    @rmd_start = '<roleMetadata>'
    @rmd_end   = '</roleMetadata>'
    @p1 = '<person><identifier type="sunetid">sunetid1</identifier><name/></person>'
    @p2 = '<person><identifier type="sunetid">sunetid2</identifier><name/></person>'
    @p3 = '<person><identifier type="sunetid">sunetid3</identifier><name/></person>'
    @p4 = '<person><identifier type="sunetid">sunetid4</identifier><name/></person>'
  end

  context "APO role metadata" do
    before(:each) do
      xml = <<-EOF
        #{@rmd_start}
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
          <role type="hydrus-collection-depositor">
             <person>
                <identifier type="sunetid">ggreen</identifier>
                <name>Green, Greg</name>
             </person>
             <group>
                <identifier type="workgroup">pasig:2011attendees</identifier>
                <name>Conference attendees</name>
              </group>
          </role>
          <role type="hydrus-collection-reviewer">
             <group>
                <identifier type="workgroup">pasig:staff</identifier>
                <name>Conference attendees</name>
             </group>
          </role>
          <role type="hydrus-collection-viewer">
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
        [:person_id, %w(brown dblack ggreen)],
        [[:role, :group,  :identifier], %w(pasig:2011attendees pasig:staff stanford)],
        [[:role, :person, :name], ["Brown, Malcolm", "Black, Delores", "Green, Greg"]],
        [[:collection_manager, :person, :identifier], %w(brown dblack)],
        [[:collection_manager, :group, :identifier], %w()],
        [:collection_owner, %w(brown dblack)],
        [[:collection_depositor, :person, :identifier], %w(ggreen)],
        [[:collection_depositor, :group, :identifier], %w(pasig:2011attendees)],
        [[:collection_reviewer, :person, :identifier], %w()],
        [[:collection_reviewer, :group, :identifier], %w(pasig:staff)],
        [[:collection_viewer, :person, :identifier], %w()],
        [[:collection_viewer, :group, :identifier], %w(stanford)],
        [[:role, :type], %w(hydrus-collection-manager hydrus-collection-depositor hydrus-collection-reviewer hydrus-collection-viewer)],
        [[:person, :identifier, :type], %w(sunetid sunetid sunetid)],
        [[:group, :identifier, :type], %w(workgroup workgroup community)],
        [[:actor], %w()],
      ]
      tests.each do |terms, exp|
        @rmdoc.term_values(*terms).should == exp
      end
    end
    
    it "should be able to exercise to_solr()" do
      sdoc = @rmdoc.to_solr
      sdoc.should be_kind_of Hash
      exp_hash = {
        "apo_register_permissions_t"                => ["sunetid:brown", "sunetid:dblack", "sunetid:ggreen", "workgroup:pasig:2011attendees"],
        "apo_role_hydrus_collection_depositor_facet"       => ["sunetid:ggreen", "workgroup:pasig:2011attendees"],
        "apo_role_hydrus_collection_depositor_t"           => ["sunetid:ggreen", "workgroup:pasig:2011attendees"],
        "apo_role_group_hydrus_collection_depositor_facet" => ["workgroup:pasig:2011attendees"],
        "apo_role_group_hydrus_collection_depositor_t"     => ["workgroup:pasig:2011attendees"],
        "apo_role_person_hydrus_collection_manager_facet"  => ["sunetid:brown", "sunetid:dblack"],
        "apo_role_person_hydrus_collection_manager_t"      => ["sunetid:brown", "sunetid:dblack"],
      }
      sdoc.should include(exp_hash)
    end
  end  # context APO object
  
  context "ITEM object role metadata" do
    before(:each) do
      xml = <<-EOF
        #{@rmd_start}
          <role type="hydrus-item-depositor">
             <person>
                <identifier type="sunetid">vviolet</identifier>
                <name>Violet, Viola</name>
             </person>
          </role>
        #{@rmd_end}
      EOF
      @rmdoc = Hydrus::RoleMetadataDS.from_xml(xml)
    end

    it "should get expected values from OM terminology" do
      tests = [
        [[:role, :person, :identifier], ['vviolet']],
        [[:role, :person, :name], ["Violet, Viola"]],
        [[:item_depositor, :person, :identifier], ['vviolet']],
        [[:role, :type], ['hydrus-item-depositor']],
        [[:person, :identifier, :type], ['sunetid']],
        [[:actor], %w()],
      ]
      tests.each do |terms, exp|
        @rmdoc.term_values(*terms).should == exp
      end
    end

    it "Should be able to insert new hydrus-item-depositor role with person node" do
      p = '<person><identifier type="sunetid"/><name/></person>'
      exp_parts = [
        @rmd_start,
        '<role type="hydrus-item-depositor">',  p, '</role>',
        @rmd_end,
      ]
      exp_xml = noko_doc(exp_parts.join '')
      rmdoc   = Hydrus::RoleMetadataDS.from_xml("#{@rmd_start}#{@rmd_end}")
      role_node = rmdoc.insert_role('hydrus-item-depositor')
      rmdoc.insert_person(role_node, "")
      rmdoc.ng_xml.should be_equivalent_to exp_xml
    end

    it "should be able to exercise to_solr()" do
      sdoc = @rmdoc.to_solr
      sdoc.should be_kind_of Hash
      exp_hash = {
        "apo_role_hydrus_item_depositor_facet"         => ["sunetid:vviolet"],
        "apo_role_hydrus_item_depositor_t"             => ["sunetid:vviolet"],
        "apo_role_person_hydrus_item_depositor_facet"  => ["sunetid:vviolet"],
        "apo_role_person_hydrus_item_depositor_t"      => ["sunetid:vviolet"],
      }
      sdoc.should include(exp_hash)
    end
  end # context item object

  it "toggle_hyphen_underscore() should work correctly" do
    rmdoc = Hydrus::RoleMetadataDS.from_xml('')
    tests = {
      # Should change.
      'hydrus-item-foo'       => 'hydrus_item_foo',
      'hydrus_item_foo'       => 'hydrus-item-foo',
      'hydrus-collection-foo' => 'hydrus_collection_foo',
      'hydrus_collection_foo' => 'hydrus-collection-foo',
      'hydrus_collection_Foo' => 'hydrus-collection-Foo',
      # No changes.
      'item-'                 => 'item-',
      'hydrus-item-'          => 'hydrus-item-',
      'xcollection_foo'       => 'xcollection_foo',
      'blah'                  => 'blah',
      ''                      => '',
    }
    tests.each do |input, exp|
      rmdoc.toggle_hyphen_underscore(input).should == exp
    end    
  end

  context "inserting nodes" do
    before(:all) do
      # empty actor node xml strings
      @ep = '<person><identifier type="sunetid"/><name/></person>'
      @egs = '<group><identifier type="stanford"/><name/></group>'
      @egw = '<group><identifier type="workgroup"/><name/></group>'
    end
    
    it "Should be able to insert new role, person, and group nodes" do
      exp_parts = [
        @rmd_start,
        '<role type="hydrus-collection-manager">',  @egw, @ep,     '</role>',
        '<role type="hydrus-collection-reviewer">', @egs, @ep, @egs, '</role>',
        @rmd_end,
      ]
      exp_xml = noko_doc(exp_parts.join '')
      rmdoc   = Hydrus::RoleMetadataDS.from_xml("#{@rmd_start}#{@rmd_end}")
      role_node1 = rmdoc.insert_role('hydrus-collection-manager')
      role_node2 = rmdoc.insert_role('hydrus-collection-reviewer')
      rmdoc.insert_group(role_node2, 'stanford')
      rmdoc.insert_person(role_node2, "")
      rmdoc.insert_group(role_node1, 'workgroup')
      rmdoc.insert_person(role_node1, "")
      rmdoc.insert_group(role_node2, 'stanford')
      rmdoc.ng_xml.should be_equivalent_to exp_xml
    end
    
    context "add_person_with_role" do
      before(:each) do
        xml = <<-EOF
          #{@rmd_start}
            <role type="hydrus-collection-manager">
              #{@p1}
            </role>
            <role type="hydrus-collection-depositor">
              #{@p3}
            </role>
          #{@rmd_end}
        EOF
        @rmdoc = Hydrus::RoleMetadataDS.from_xml(xml)
      end
      
      it "should add the person node to an existing role node" do
        exp_parts = [
          @rmd_start,
          '<role type="hydrus-collection-manager">',  @p1, @p2, '</role>',
          '<role type="hydrus-collection-depositor">',  @p3, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_person_with_role("sunetid2", 'hydrus-collection-manager')
        @rmdoc.ng_xml.should be_equivalent_to exp_xml
        exp_parts = [
          @rmd_start,
          '<role type="hydrus-collection-manager">',  @p1, @p2, '</role>',
          '<role type="hydrus-collection-depositor">',  @p3, @p4, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_person_with_role("sunetid4", 'hydrus-collection-depositor')
        @rmdoc.ng_xml.should be_equivalent_to exp_xml
      end
      
      it "should create the role node when none exists" do
        exp_parts = [
          @rmd_start,
          '<role type="hydrus-collection-manager">',  @p1, '</role>',
          '<role type="hydrus-collection-depositor">',  @p3, '</role>',
          '<role type="foo-role">',  @p2, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_person_with_role("sunetid2", 'foo-role')
        @rmdoc.ng_xml.should be_equivalent_to exp_xml
      end
      
      it "add_empty_person_to_role should insert an empty person node as a child of the role node" do
        exp_parts = [
          @rmd_start,
          '<role type="hydrus-collection-manager">',  @p1, @ep, '</role>',
          '<role type="hydrus-collection-depositor">',  @p3, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_empty_person_to_role('hydrus-collection-manager')
        @rmdoc.ng_xml.should be_equivalent_to exp_xml
      end  
    end # context add_person_of_role
  end # context inserting nodes

  it "the blank template should match our expectations" do
    exp_xml = %Q(
      #{@rmd_start}
      #{@rmd_end}
    )
    exp_xml = noko_doc(exp_xml)
    rmdoc = Hydrus::RoleMetadataDS.new(nil, nil)
    rmdoc.ng_xml.should be_equivalent_to exp_xml
  end

end
