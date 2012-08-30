require 'spec_helper'

describe Hydrus::Collection do

  before(:each) do
    @hc = Hydrus::Collection.new
  end

  it "can exercise a stubbed version of create()" do
    # More substantive testing is done at integration level.
    druid = 'druid:BLAH'
    stubs = [
      :remove_relationship,
      :assert_content_model,
      :augment_identity_metadata,
    ]
    stubs.each { |s| @hc.should_receive(s) }
    @hc.should_receive(:save).with(:no_edit_logging => true)
    @hc.stub(:pid).and_return(druid)
    @hc.stub(:adapt_to).and_return(@hc)
    apo = Hydrus::AdminPolicyObject.new
    Hydrus::AdminPolicyObject.stub(:create).and_return(apo)
    Hydrus::GenericObject.stub(:register_dor_object).and_return(@hc)
    Hydrus::Collection.create('USERFOO').pid.should == druid
  end

  describe "publish()" do

    # More substantive testing is done at integration level.

    before(:each) do
      apo_druid = 'druid:oo000oo9991'
      apo = Hydrus::AdminPolicyObject.new(:pid => apo_druid)
      @hc.stub(:apo).and_return(apo)
    end
    
    it "publish(no) should set deposit_status to closed, and add an event" do
      @hc.apo.deposit_status.should == ''
      @hc.get_hydrus_events.size.should == 0
      @hc.should_not_receive(:workflow_step_is_done)
      @hc.publish('no')
      @hc.apo.deposit_status.should == 'closed'
      @hc.get_hydrus_events.size.should > 0
    end
    
    it "if already published, should set titles but not call approve" do
      hc_title      = 'blah blah blah'
      apo_title     = "APO for #{hc_title}"
      @hc.title     = hc_title
      @hc.apo.title = apo_title
      @hc.apo.deposit_status.should == ''
      @hc.get_hydrus_events.size.should == 0
      @hc.stub(:workflow_step_is_done).and_return(true)
      @hc.should_not_receive(:approve)
      @hc.should_not_receive(:complete_workflow_step)
      @hc.publish('yes')
      @hc.apo.deposit_status.should == 'open'
      @hc.get_hydrus_events.size.should > 0
      @hc.apo.identityMetadata.objectLabel.should == [apo_title]
      @hc.apo.descMetadata.title.should           == [apo_title]
      @hc.identityMetadata.objectLabel.should     == [hc_title]
      @hc.label.should                            == hc_title
      @hc.apo.label.should                        == apo_title
    end
    
    it "if not published, should call approve" do
      @hc.stub(:workflow_step_is_done).and_return(false)
      @hc.should_receive(:approve)
      @hc.should_receive(:complete_workflow_step)
      @hc.publish('yes')
      @hc.apo.deposit_status.should == 'open'
      @hc.get_hydrus_events.size.should > 0
    end
    
  end

  describe "valid?()" do

    before(:each) do
      xml = <<-EOXML
        <workflows>
          <workflow id="foo">
            <process status="waiting" name="aa"/>
            <process status="waiting" name="bb"/>
          </workflow>
          <workflow id="hydrusAssemblyWF">
            <process status="completed" name="start-deposit" lifecycle="registered"/>
            <process status="waiting"   name="submit"/>
            <process status="waiting"   name="approve"/>
            <process status="waiting"   name="start-assembly"/>
          </workflow>
        </workflows>
      EOXML
      @workflow = Dor::WorkflowDs.from_xml(noko_doc(xml))
      @apo      = Hydrus::AdminPolicyObject.new
      @apo.stub(:is_open).and_return(true)
      @hc.stub(:workflows).and_return(@workflow)
      @hc.stub(:apo).and_return(@apo)
    end

    it "should validate both Collection and its APO, and merge their errors" do
      @hc.valid?.should == false
      es = @hc.errors.messages
      es.should include(:pid, :embargo)
    end

    it "should get only the Collection errors when the APO is valid" do
      @apo.stub(:'valid?').and_return(true)
      @hc.valid?.should == false
      es = @hc.errors.messages
      es.should     include(:pid)
      es.should_not include(:embargo)
    end

    it "should return true when both Collection and APO are valid" do
      @hc.stub(:pid).and_return('druid:tt000tt0001')
      @apo.stub(:'valid?').and_return(true)
      @hc.valid?.should == true
    end

  end

  it "is_destroyable() should return true only if Collection is unpublished with 0 Items" do
    tests = [
      [false, false, true],
      [false, true,  false],
      [true,  false, false],
      [false, false, true],
    ]
    tests.each do |is_p, has_i, exp|
      @hc.stub(:is_published).and_return(is_p)
      @hc.stub(:has_items).and_return(has_i)
      @hc.is_destroyable.should == exp
    end
  end

  it "has_items() should return true only if Collection has Items" do
    @hc.stub(:hydrus_items).and_return([])
    @hc.has_items.should == false
    @hc.stub(:hydrus_items).and_return([0, 11, 22])
    @hc.has_items.should == true
  end
  
  it "is_open() should delegate to the APO" do
    apo = double('apo', :is_open => false)
    @hc.stub(:apo).and_return(apo)
    @hc.is_open.should == false
    apo = double('apo', :is_open => true)
    @hc.stub(:apo).and_return(apo)
    @hc.is_open.should == true
  end
  
  context "APO roleMetadataDS delegation-y methods" do
    before(:each) do
      apo = Hydrus::AdminPolicyObject.new
      role_xml = <<-EOF
        <roleMetadata>
          <role type="hydrus-collection-manager">
            <person><identifier type="sunetid">sunetid1</identifier><name/></person>
            <person><identifier type="sunetid">sunetid2</identifier><name/></person>
          </role>
          <role type="hydrus-item-depositor">
            <person><identifier type="sunetid">sunetid3</identifier><name/></person>
          </role>
        </roleMetadata>
      EOF
      @rmdoc = Hydrus::RoleMetadataDS.from_xml(role_xml)
      apo.stub(:roleMetadata).and_return(@rmdoc)
      
      @hc = Hydrus::Collection.new
      @hc.stub(:apo).and_return(apo)
    end
    
    it "add_empty_person_to_role should work" do
      @hc.add_empty_person_to_role('hydrus-collection-manager')
      @rmdoc.ng_xml.should be_equivalent_to <<-EOF
        <roleMetadata>
          <role type="hydrus-collection-manager">
            <person><identifier type="sunetid">sunetid1</identifier><name/></person>
            <person><identifier type="sunetid">sunetid2</identifier><name/></person>
            <person><identifier type="sunetid" /><name/></person>
          </role>
          <role type="hydrus-item-depositor">
            <person><identifier type="sunetid">sunetid3</identifier><name/></person>
          </role>
        </roleMetadata>
      EOF
      @hc.add_empty_person_to_role('foo')
      @rmdoc.ng_xml.should be_equivalent_to <<-EOF
        <roleMetadata>
          <role type="hydrus-collection-manager">
            <person><identifier type="sunetid">sunetid1</identifier><name/></person>
            <person><identifier type="sunetid">sunetid2</identifier><name/></person>
            <person><identifier type="sunetid" /><name/></person>
          </role>
          <role type="hydrus-item-depositor">
            <person><identifier type="sunetid">sunetid3</identifier><name/></person>
          </role>
          <role type="foo">
            <person><identifier type="sunetid" /><name/></person>
          </role>
        </roleMetadata>
      EOF
    end

    it "apo_person_roles= should correctly update APO roleMetadtaDS" do
      @hc.apo_person_roles = {
        'hydrus-collection-manager' => 'brown, dblack',
        'hydrus-item-depositor'     => 'bblue',
      } 
      @rmdoc.ng_xml.should be_equivalent_to <<-EOF
        <roleMetadata>
          <role type="hydrus-collection-manager">
            <person><identifier type="sunetid">brown</identifier><name/></person>
            <person><identifier type="sunetid">dblack</identifier><name/></person>
          </role>
          <role type="hydrus-item-depositor">
            <person><identifier type="sunetid">bblue</identifier><name/></person>
          </role>
        </roleMetadata>
      EOF
    end
    
    it "apo_persons_with_role() should delegate to apo.persons_with_role()" do
      role = 'foo_role'
      apo = double('apo')
      apo.should_receive(:persons_with_role).with(role)
      @hc.stub(:apo).and_return(apo)
      @hc.apo_persons_with_role(role)
    end

  end

  it "can exercise tracked_fields()" do
    @hc.tracked_fields.should be_an_instance_of(Hash)
  end

end
