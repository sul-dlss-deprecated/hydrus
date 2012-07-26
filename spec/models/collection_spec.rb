require 'spec_helper'

describe Hydrus::Collection do
    
  it "should be valid unless publish is set on both the apo and the collection" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.should be_valid
    col.apo.should be_valid
    col.object_valid?.should == true  
  end

  it "should have the associated apo deposit status set correctly when the collection is published" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.publish.should == false
    col.apo.deposit_status.should == ''
    col.clicked_publish?.should == false
    col.publish="true"
    col.apo.deposit_status.should == 'open'
    col.apo.open_for_deposit?.should == true
    col.publish="false"
    col.apo.deposit_status.should == 'closed'
    col.apo.open_for_deposit?.should == false
  end

  it "new collections that are published should be invalid if required fields are not set, including those on the APO" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.should be_valid
    col.apo.should be_valid
    col.object_valid?.should == true
    col.apo.deposit_status.should == ''
    col.apo.open_for_deposit?.should == false
    col.publish=true
    col.apo.deposit_status.should == 'open'
    col.apo.open_for_deposit?.should == true    
    col.should_not be_valid
    col.apo.should_not be_valid
    col.object_valid?.should == false
    col.object_error_messages[:title].should_not be_nil
    col.object_error_messages[:embargo].should_not be_nil    
    col.object_error_messages[:abstract].should_not be_nil    
  end

  it "new collections that are published should be valid when options are correctly set" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.publish="true"
    col.object_valid?.should == false
    col.title='title'
    col.abstract='abstract'
    col.contact='test@test.com'
    col.embargo_option='none'
    col.license_option='none'
    col.object_valid?.should == true    
    col.embargo_option='varies'
    col.object_valid?.should == false    
    col.embargo='1 year'
    col.object_valid?.should == true
  end
  
  context "APO roleMetadataDS delegation-y methods" do
    before(:each) do
      apo = Hydrus::AdminPolicyObject.new
      role_xml = <<-EOF
        <roleMetadata>
          <role type="collection-manager">
            <person><identifier type="sunetid">sunetid1</identifier><name/></person>
            <person><identifier type="sunetid">sunetid2</identifier><name/></person>
          </role>
          <role type="collection-depositor">
            <person><identifier type="sunetid">sunetid3</identifier><name/></person>
          </role>
        </roleMetadata>
      EOF
      @rmdoc = Hydrus::RoleMetadataDS.from_xml(role_xml)
      apo.stub(:roleMetadata).and_return(@rmdoc)
      
      @hc = Hydrus::Collection.new
      @hc.stub(:apo).and_return(apo)
    end
    
    # it "get_person_role should retrieve the correct value" do
    #   @hc.get_person_role('sunetid1').should == 'collection-manager'
    #   @hc.get_person_role('sunetid2').should == 'collection-manager'
    #   @hc.get_person_role('sunetid3').should == 'collection-depositor'
    # end

    it "add_empty_person_to_role should work" do
      @hc.add_empty_person_to_role('collection-manager')
      @rmdoc.ng_xml.should be_equivalent_to <<-EOF
        <roleMetadata>
          <role type="collection-manager">
            <person><identifier type="sunetid">sunetid1</identifier><name/></person>
            <person><identifier type="sunetid">sunetid2</identifier><name/></person>
            <person><identifier type="sunetid" /><name/></person>
          </role>
          <role type="collection-depositor">
            <person><identifier type="sunetid">sunetid3</identifier><name/></person>
          </role>
        </roleMetadata>
      EOF
      @hc.add_empty_person_to_role('foo')
      @rmdoc.ng_xml.should be_equivalent_to <<-EOF
        <roleMetadata>
          <role type="collection-manager">
            <person><identifier type="sunetid">sunetid1</identifier><name/></person>
            <person><identifier type="sunetid">sunetid2</identifier><name/></person>
            <person><identifier type="sunetid" /><name/></person>
          </role>
          <role type="collection-depositor">
            <person><identifier type="sunetid">sunetid3</identifier><name/></person>
          </role>
          <role type="foo">
            <person><identifier type="sunetid" /><name/></person>
          </role>
        </roleMetadata>
      EOF
    end

    it "person_roles= should correctly update APO roleMetadtaDS" do
      @hc.person_roles = {
        '0' => {
          'id'   => "brown",
          'role' => "collection-manager",
        },
        '1' => {
          'id'   => "dblack",
          'role' => "collection-manager",
        },
        '2' => {
          'id'   => "ggreen",
          'role' => "collection-depositor",
        },
      } 
      @rmdoc.ng_xml.should be_equivalent_to <<-EOF
        <roleMetadata>
          <role type="collection-manager">
            <person><identifier type="sunetid">brown</identifier><name/></person>
            <person><identifier type="sunetid">dblack</identifier><name/></person>
          </role>
          <role type="collection-depositor">
            <person><identifier type="sunetid">ggreen</identifier><name/></person>
          </role>
        </roleMetadata>
      EOF
    end
    
    it "remove_actor should correctly update APO roleMetadataDS" do
      @hc.remove_actor('sunetid1', 'collection-manager')
      @rmdoc.ng_xml.should be_equivalent_to <<-EOF
        <roleMetadata>
          <role type="collection-manager">
            <person><identifier type="sunetid">sunetid2</identifier><name/></person>
          </role>
          <role type="collection-depositor">
            <person><identifier type="sunetid">sunetid3</identifier><name/></person>
          </role>
        </roleMetadata>
      EOF
    end
  
  end # context APO roleMetadataDS 

  
end
