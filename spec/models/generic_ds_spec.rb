require 'spec_helper'

describe Hydrus::GenericDS do

  before(:all) do
    @rmd_start = '<roleMetadata>'
    @rmd_end   = '</roleMetadata>'
    @p0 = '<person><identifier type="sunetid">sunetid0</identifier><name/></person>'
    @p1 = '<person><identifier type="sunetid">sunetid1</identifier><name/></person>'
    @p2 = '<person><identifier type="sunetid">sunetid2</identifier><name/></person>'
    @p3 = '<person><identifier type="sunetid">sunetid3</identifier><name/></person>'
    @rmd_xml = <<-EOF
      #{@rmd_start}
        <role type="collection-manager">
          #{@p0}
          #{@p1}
          #{@p2}
        </role>
        <role type="collection-depositor">
          #{@p3}
        </role>
      #{@rmd_end}
    EOF
  end

  before(:each) do
    @rmdoc = Hydrus::RoleMetadataDS.from_xml(@rmd_xml)
  end

  describe "remove_nodes()" do
    
    it "should be able to remove all nodes of a particular type" do
      # Remove the <person> nodes.
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="collection-manager" />
          <role type="collection-depositor" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes(:person)
      @rmdoc.ng_xml.should be_equivalent_to exp_xml
      # Remove the <role> node for collection manager.
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="collection-depositor" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes(:collection_manager)
      @rmdoc.ng_xml.should be_equivalent_to exp_xml
      # Remove the <role> nodes.
      @rmdoc.remove_nodes(:role)
      @rmdoc.ng_xml.should be_equivalent_to "#{@rmd_start}#{@rmd_end}"
    end

    it "should be able to pass multiple terms into the method" do
      exp_xml = <<-EOF
        #{@rmd_start}
          <role type="collection-manager" />
          <role type="collection-depositor" />
        #{@rmd_end}
      EOF
      @rmdoc.remove_nodes(:role, :person)
      @rmdoc.ng_xml.should be_equivalent_to exp_xml
    end

    it "should do nothing quietly called for nodes that do not exist in xml" do
      @rmdoc.remove_nodes(:item_depositor)
      @rmdoc.ng_xml.should be_equivalent_to @rmd_xml
    end

  end

   describe "remove_node()" do

    it "should remove correct node" do
      @rmdoc.remove_node(:person, 2)
      @rmdoc.remove_node(:person, 0)
      exp = <<-EOF
        #{@rmd_start}
          <role type="collection-manager">
            #{@p1}
          </role>
          <role type="collection-depositor">
            #{@p3}
          </role>
        #{@rmd_end}
      EOF
      @rmdoc.ng_xml.should be_equivalent_to(exp)
    end

  end

end
