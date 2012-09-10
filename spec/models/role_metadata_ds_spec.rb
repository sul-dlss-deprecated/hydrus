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
          </role>
          <role type="hydrus-collection-reviewer">
             <person>
                <identifier type="sunetid">bblue</identifier>
                <name>Blue, Bill</name>
             </person>
          </role>
        #{@rmd_end}
      EOF
      @rmdoc = Hydrus::RoleMetadataDS.from_xml(xml)
    end

    it "should get expected values from OM terminology" do
      tests = [
        [[:role, :person, :identifier], %w(brown dblack ggreen bblue)],
        [:person_id, %w(brown dblack ggreen bblue)],
        [[:role, :person, :name], ["Brown, Malcolm", "Black, Delores", "Green, Greg", "Blue, Bill"]],
        [[:collection_manager, :person, :identifier], %w(brown dblack)],
        [[:collection_depositor, :person, :identifier], %w(ggreen)],
        [[:collection_reviewer, :person, :identifier], %w(bblue)],
        [[:collection_viewer, :person, :identifier], %w()],
        [[:role, :type], %w(hydrus-collection-manager hydrus-collection-depositor hydrus-collection-reviewer)],
      ]
      tests.each do |terms, exp|
        @rmdoc.term_values(*terms).should == exp
      end
    end

  end

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

  end

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
      @ep = '<person><identifier type="sunetid"/><name/></person>'
    end

    it "Should be able to insert new role and person nodes" do
      exp_parts = [
        @rmd_start,
        '<role type="hydrus-collection-manager">',  @ep, '</role>',
        '<role type="hydrus-collection-reviewer">', @ep, '</role>',
        @rmd_end,
      ]
      exp_xml = noko_doc(exp_parts.join '')
      rmdoc   = Hydrus::RoleMetadataDS.from_xml("#{@rmd_start}#{@rmd_end}")
      role_node1 = rmdoc.insert_role('hydrus-collection-manager')
      role_node2 = rmdoc.insert_role('hydrus-collection-reviewer')
      rmdoc.insert_person(role_node2, "")
      rmdoc.insert_person(role_node1, "")
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

    end

  end

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
