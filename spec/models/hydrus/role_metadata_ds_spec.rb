require 'spec_helper'

describe Hydrus::RoleMetadataDS, type: :model do

  before(:all) do
    @rmd_start = '<roleMetadata>'
    @rmd_end   = '</roleMetadata>'
    @p1 = '<person><identifier type="sunetid">sunetid1</identifier><name/></person>'
    @p2 = '<person><identifier type="sunetid">sunetid2</identifier><name/></person>'
    @p3 = '<person><identifier type="sunetid">sunetid3</identifier><name/></person>'
    @p4 = '<person><identifier type="sunetid">sunetid4</identifier><name/></person>'
    @g1 = '<group><identifier type="workgroup">dlss:pmag-staff</identifier></group>'
    @g2 = '<group><identifier type="workgroup">dlss:developers</identifier></group>'
  end

  context "APO role metadata" do

    before(:each) do
      xml = <<-EOF
        #{@rmd_start}
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
          <role type="hydrus-collection-depositor">
             <person>
                <identifier type="sunetid">archivist3</identifier>
                <name>Archivist, Three</name>
             </person>
          </role>
          <role type="hydrus-collection-reviewer">
             <person>
                <identifier type="sunetid">archivist6</identifier>
                <name>Archivist, Six</name>
             </person>
          </role>
        #{@rmd_end}
      EOF
      @rmdoc = Hydrus::RoleMetadataDS.from_xml(xml)
    end

    it "should get expected values from OM terminology" do
      expect(@rmdoc.term_values(:role, :person, :identifier)).to eq(%w(archivist4 archivist5 archivist3 archivist6))
      expect(@rmdoc.term_values(:person_id)).to eq(%w(archivist4 archivist5 archivist3 archivist6))
      expect(@rmdoc.term_values(:role, :person, :name)).to eq(["Archivist, Four", "Archivist, Five", "Archivist, Three", "Archivist, Six"])
      expect(@rmdoc.term_values(:collection_manager, :person, :identifier)).to eq(%w(archivist4 archivist5))
      expect(@rmdoc.term_values(:collection_depositor, :person, :identifier)).to eq(%w(archivist3))
      expect(@rmdoc.term_values(:collection_reviewer, :person, :identifier)).to eq(%w(archivist6))
      expect(@rmdoc.term_values(:collection_viewer, :person, :identifier)).to eq(%w())
      expect(@rmdoc.term_values(:role, :type)).to eq(%w(hydrus-collection-manager hydrus-collection-depositor hydrus-collection-reviewer))
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
      expect(@rmdoc.term_values(:role, :person, :identifier)).to eq(['vviolet'])
      expect(@rmdoc.term_values(:role, :person, :name)).to eq(["Violet, Viola"])
      expect(@rmdoc.term_values(:item_depositor, :person, :identifier)).to eq(['vviolet'])
      expect(@rmdoc.term_values(:role, :type)).to eq(['hydrus-item-depositor'])
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
      expect(rmdoc.ng_xml).to be_equivalent_to exp_xml
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
      expect(rmdoc.ng_xml).to be_equivalent_to exp_xml
    end

    context "add_person_with_role()" do

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
        expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
        exp_parts = [
          @rmd_start,
          '<role type="hydrus-collection-manager">',  @p1, @p2, '</role>',
          '<role type="hydrus-collection-depositor">',  @p3, @p4, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_person_with_role("sunetid4", 'hydrus-collection-depositor')
        expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
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
        expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
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
        expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
      end

    end

    context "add_group_with_role()" do

      before(:each) do
        xml = <<-EOF
          #{@rmd_start}
          #{@rmd_end}
        EOF
        @rmdoc = Hydrus::RoleMetadataDS.from_xml(xml)
      end

      it "should add groups under roles" do
        exp_parts = [
          @rmd_start,
          '<role type="dor-apo-manager">', @g1, @g2, '</role>',
          @rmd_end,
        ]
        exp_xml = noko_doc(exp_parts.join '')
        @rmdoc.add_group_with_role("dlss:pmag-staff", "dor-apo-manager")
        @rmdoc.add_group_with_role("dlss:developers", "dor-apo-manager")
        expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
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
    expect(rmdoc.ng_xml).to be_equivalent_to exp_xml
  end

end
