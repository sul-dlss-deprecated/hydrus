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
        [[:role, :type], %w(collection-manager collection-depositor collection-reviewer collection-viewer)],
        [[:person, :identifier, :type], %w(sunetid sunetid sunetid)],
        [[:group, :identifier, :type], %w(workgroup workgroup community)],
        [[:actor], %w()],
      ]
      tests.each do |terms, exp|
        @rmdoc.term_values(*terms).should == exp
      end
    end
    
    it "should be able to retrieve the role for a person identifier" do
      @rmdoc.get_person_role('brown').should == "collection-manager"
      @rmdoc.get_person_role('dblack').should == "collection-manager"
      @rmdoc.get_person_role('ggreen').should == "collection-depositor"
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
  end  # context APO object
  
  context "ITEM object role metadata" do
    before(:each) do
      xml = <<-EOF
        #{@rmd_start}
          <role type="item-depositor">
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
        [[:role, :type], ['item-depositor']],
        [[:person, :identifier, :type], ['sunetid']],
        [[:actor], %w()],
      ]
      tests.each do |terms, exp|
        @rmdoc.term_values(*terms).should == exp
      end
    end

    it "Should be able to insert new item-depositor role with person node" do
      p = '<person><identifier type="sunetid"/><name/></person>'
      exp_parts = [
        @rmd_start,
        '<role type="item-depositor">',  p, '</role>',
        @rmd_end,
      ]
      exp_xml = noko_doc(exp_parts.join '')
      rmdoc   = Hydrus::RoleMetadataDS.from_xml("#{@rmd_start}#{@rmd_end}")
      role_node = rmdoc.insert_role('item-depositor')
      rmdoc.insert_person(role_node, "")
      rmdoc.ng_xml.should be_equivalent_to exp_xml
    end

    it "should be able to exercise to_solr()" do
      sdoc = @rmdoc.to_solr
      sdoc.should be_kind_of Hash
      exp_hash = {
        "apo_role_item_depositor_facet"         => ["sunetid:vviolet"],
        "apo_role_item_depositor_t"             => ["sunetid:vviolet"],
        "apo_role_person_item_depositor_facet"  => ["sunetid:vviolet"],
        "apo_role_person_item_depositor_t"      => ["sunetid:vviolet"],
      }
      sdoc.should include(exp_hash)
    end
  end # context item object

  it "toggle_hyphen_underscore() should work correctly" do
    rmdoc = Hydrus::RoleMetadataDS.from_xml('')
    tests = {
      # Should change.
      'item-foo'        => 'item_foo',
      'item_foo'        => 'item-foo',
      'collection-foo'  => 'collection_foo',
      'collection_foo'  => 'collection-foo',
      'collection_Foo'  => 'collection-Foo',
      # No changes.
      'item-'           => 'item-',
      'xcollection_foo' => 'xcollection_foo',
      'blah'            => 'blah',
      ''                => '',
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
        '<role type="collection-manager">',  @egw, @ep,     '</role>',
        '<role type="collection-reviewer">', @egs, @ep, @egs, '</role>',
        @rmd_end,
      ]
      exp_xml = noko_doc(exp_parts.join '')
      rmdoc   = Hydrus::RoleMetadataDS.from_xml("#{@rmd_start}#{@rmd_end}")
      role_node1 = rmdoc.insert_role('collection-manager')
      role_node2 = rmdoc.insert_role('collection-reviewer')
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
            <role type="collection-manager">
              #{@p1}
            </role>
            <role type="collection-depositor">
              #{@p3}
            </role>
          #{@rmd_end}
        EOF
        @rmdoc = Hydrus::RoleMetadataDS.from_xml(xml)
      end
      
      it "should add the person node to an existing role node" do
        exp_parts = [
          @rmd_start,
          '<role type="collection-manager">',  @p1, @p2, '</role>',
          '<role type="collection-depositor">',  @p3, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_person_with_role("sunetid2", 'collection-manager')
        @rmdoc.ng_xml.should be_equivalent_to exp_xml
        exp_parts = [
          @rmd_start,
          '<role type="collection-manager">',  @p1, @p2, '</role>',
          '<role type="collection-depositor">',  @p3, @p4, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_person_with_role("sunetid4", 'collection-depositor')
        @rmdoc.ng_xml.should be_equivalent_to exp_xml
      end
      
      it "should create the role node when none exists" do
        exp_parts = [
          @rmd_start,
          '<role type="collection-manager">',  @p1, '</role>',
          '<role type="collection-depositor">',  @p3, '</role>',
          '<role type="foo-role">',  @p2, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_person_with_role("sunetid2", 'foo-role')
        @rmdoc.ng_xml.should be_equivalent_to exp_xml
      end
      
      it "add_empty_person_of_role should insert an empty person node as a child of the role node" do
        exp_parts = [
          @rmd_start,
          '<role type="collection-manager">',  @p1, @ep, '</role>',
          '<role type="collection-depositor">',  @p3, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_empty_person_of_role('collection-manager')
        @rmdoc.ng_xml.should be_equivalent_to exp_xml
      end  
    end # context add_person_of_role
  end # context inserting nodes

  context "Remove nodes" do
    before(:each) do
      @start_xml = <<-EOF
        #{@rmd_start}
          <role type="collection-manager">
            #{@p1}
            #{@p2}
          </role>
          <role type="collection-depositor">
            #{@p3}
          </role>
        #{@rmd_end}
      EOF
      @rmdoc = Hydrus::RoleMetadataDS.from_xml(@start_xml)
    end

    it "should be able to remove all nodes of a type using remove_nodes()" do
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="collection-manager" />
          <role type="collection-depositor" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes(:person)
      @rmdoc.ng_xml.should be_equivalent_to exp_xml
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="collection-depositor" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes(:collection_manager)
      @rmdoc.ng_xml.should be_equivalent_to exp_xml
      @rmdoc.remove_nodes(:role)
      @rmdoc.ng_xml.should be_equivalent_to "#{@rmd_start}#{@rmd_end}"
    end
    it "should do nothing quietly when remove_nodes is called for nodes in terminology that don't exist in xml" do
      @rmdoc.remove_nodes(:item_depositor)
      @rmdoc.ng_xml.should be_equivalent_to @start_xml
    end
  end # context remove_nodes


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
