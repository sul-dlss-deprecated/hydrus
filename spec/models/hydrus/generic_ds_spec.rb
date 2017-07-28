require 'spec_helper'

describe Hydrus::GenericDS, type: :model do
  before(:all) do
    @rmd_start = '<roleMetadata>'
    @rmd_end   = '</roleMetadata>'
    @p0 = '<person><identifier type="sunetid">sunetid0</identifier><name/></person>'
    @p1 = '<person><identifier type="sunetid">sunetid1</identifier><name/></person>'
    @p2 = '<person><identifier type="sunetid">sunetid2</identifier><name/></person>'
    @p3 = '<person><identifier type="sunetid">sunetid3</identifier><name/></person>'
    @p4 = '<person><identifier type="sunetid">sunetid4</identifier><name/></person>'
    @rmd_xml = <<-EOF
      #{@rmd_start}
        <role type="hydrus-collection-manager">
          #{@p0}
          #{@p1}
          #{@p2}
        </role>
        <role type="hydrus-collection-item-depositor">
          #{@p3}
        </role>
        <role type="hydrus-item-manager">
          #{@p4}
        </role>
      #{@rmd_end}
    EOF
  end

  before(:each) do
    @rmdoc = Hydrus::RoleMetadataDS.from_xml(noko_doc(@rmd_xml))
  end

  describe 'remove_nodes()' do
    it 'should be able to remove all nodes of a particular type' do
      # Remove the <person> nodes.
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="hydrus-collection-manager" />
          <role type="hydrus-item-manager" />
          <role type="hydrus-collection-item-depositor" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes(:role, :person)
      expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
      # Remove the <role> node for collection manager.
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="hydrus-collection-item-depositor" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes(:collection_manager)
      @rmdoc.remove_nodes(:item_manager)
      expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
      # Remove the <role> nodes.
      @rmdoc.remove_nodes(:role)
      expect(@rmdoc.ng_xml).to be_equivalent_to "#{@rmd_start}#{@rmd_end}"
    end

    it 'should be able to pass multiple terms into the method' do
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="hydrus-collection-manager" />
          <role type="hydrus-collection-item-depositor" />
          <role type="hydrus-item-manager" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes(:role, :person)
      expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
    end

    it 'should do nothing quietly called for nodes that do not exist in xml' do
      @rmdoc.remove_nodes(:collection_reviewer)
      expect(@rmdoc.ng_xml).to be_equivalent_to @rmd_xml
    end
  end

  describe 'remove_nodes_by_xpath()' do
    it 'should be able to remove nodes using xpath queries' do
      # Remove the <person> nodes.
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="hydrus-collection-manager" />
          <role type="hydrus-collection-item-depositor" />
          <role type="hydrus-item-manager" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes_by_xpath('//role/person')
      expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
      # Remove the <role> node for collection manager.
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="hydrus-collection-item-depositor" />
          <role type="hydrus-item-manager" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes_by_xpath('//role[@type="hydrus-collection-manager"]')
      expect(@rmdoc.ng_xml).to be_equivalent_to exp_xml
      # Remove the <role> nodes.
      @rmdoc.remove_nodes_by_xpath('//role')
      expect(@rmdoc.ng_xml).to be_equivalent_to "#{@rmd_start}#{@rmd_end}"
    end

    it 'should do nothing quietly called for nodes that do not exist in xml' do
      @rmdoc.remove_nodes_by_xpath('//foobar')
      expect(@rmdoc.ng_xml).to be_equivalent_to @rmd_xml
    end
  end

  describe 'remove_node()' do
    it 'should remove correct node' do
      @rmdoc.remove_node(:role, 1)
      exp = <<-EOF
        #{@rmd_start}
          <role type="hydrus-collection-manager">
            #{@p0}
            #{@p1}
            #{@p2}
          </role>
          <role type="hydrus-item-manager">
            #{@p4}
          </role>
        #{@rmd_end}
      EOF
      expect(@rmdoc.ng_xml).to be_equivalent_to(exp)
    end
  end

  describe 'adding nodes' do
    it 'add_hydrus_child_node()' do
      n = @rmdoc.find_by_terms(:role).size
      @rmdoc.add_hydrus_child_node(@rmdoc.ng_xml.root, :role, 'blah')
      roles = @rmdoc.find_by_terms(:role)
      expect(roles.size).to eq(n + 1)
      expect(roles.last['type']).to eq('blah')
    end

    it 'add_hydrus_next_sibling_node(): siblings already exist' do
      n = @rmdoc.find_by_terms(:role).size
      @rmdoc.add_hydrus_next_sibling_node(:role, :role, 'blah')
      roles = @rmdoc.find_by_terms(:role)
      expect(roles.size).to eq(n + 1)
      expect(roles.last['type']).to eq('blah')
    end

    it 'add_hydrus_next_sibling_node(): siblings do not exist' do
      @rmdoc.remove_nodes(:role)
      expect(@rmdoc.find_by_terms(:role).size).to eq(0)
      @rmdoc.add_hydrus_next_sibling_node(:role, :role, 'blah')
      roles = @rmdoc.find_by_terms(:role)
      expect(roles.size).to eq(1)
      expect(roles.last['type']).to eq('blah')
    end
    
  end
end
