require 'spec_helper'


describe Hydrus::GenericObject do

  before(:each) do
    @go      = Hydrus::GenericObject.new
    @apo_pid = 'druid:oo000oo0002'
  end

  it "apo() should return a new blank apo if the apo_pid is nil" do
    @go.apo.class.should == Hydrus::AdminPolicyObject
  end

  it "apo() should return fedora object if the apo_pid is defined" do
    mfo = double('mock_fedora_object')
    @go.instance_variable_set('@apo_pid', @apo_pid)
    @go.stub(:get_fedora_item).and_return mfo
    @go.apo.should == mfo
  end

  it "apo_pid() should get the correct PID from admin_policy_object_ids()" do
    exp = 'foobar'
    @go.stub(:admin_policy_object_ids).and_return [exp, 11, 22]
    @go.should_receive :admin_policy_object_ids
    @go.apo_pid.should == exp
  end

  it "apo_pid() should get PID directly from @apo_pid when it is defined" do
    exp = 'foobarfubb'
    @go.instance_variable_set('@apo_pid', exp)
    @go.stub(:admin_policy_object_ids).and_return ['doh', 11, 22]
    @go.should_not_receive :admin_policy_object_ids
    @go.apo_pid.should == exp
  end

  it "can exercise discover_access()" do
    @go.discover_access.should == ""
  end

  it "can exercise object_type()" do
    fake_imd = double('fake_imd', :objectType => [123,456])
    @go.should_receive(:identityMetadata).and_return(fake_imd)
    @go.object_type.should == 123
  end

  it "can exercise url()" do
    @go.url.should == "http://purl.stanford.edu/__DO_NOT_USE__"
  end

  it "can exercise related_items()" do
    ris = @go.related_items
    ris.size.should == 1
    ri = ris.first
    ri.title.should == ''
    ri.url.should == ''
  end

  describe "registration" do

    it "dor_registration_params() should return the expected hash" do
      # Non-APO: hash should include initiate_workflow.
      args = %w(whobar item somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      drp.should be_instance_of Hash
      drp[:admin_policy].should == args.last
      drp.should include(:initiate_workflow)
      # APO: hash should not includes initiate_workflow.
      args = %w(whobar adminPolicy somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      drp.should be_instance_of Hash
      drp.should include(:initiate_workflow)
    end

    it "should be able to exercise register_dor_object(), using stubbed call to Dor" do
      args = %w(whobar item somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      expectation = Dor::RegistrationService.should_receive(:register_object)
      expectation.with(hash_including(*drp.keys))
      Hydrus::GenericObject.register_dor_object(nil, nil, nil)
    end

  end

  describe "class methods" do
    it "should define a licenses hash" do
      Hydrus::GenericObject.licenses.should be_a Hash
    end
    describe "license_commons" do
      it "should define be a hash" do
        Hydrus::GenericObject.license_commons.should be_a Hash
      end
      it "keys should all match license types" do
        Hydrus::GenericObject.license_commons.keys.should == Hydrus::GenericObject.licenses.keys
      end
    end
    it "should have a license_human method that will return a human readible value for a license code" do
      Hydrus::GenericObject.license_human("cc-by").should == "CC BY Attribution"
      Hydrus::GenericObject.license_human("cc-by-nc-sa").should == "CC BY-NC-SA Attribution-NonCommercial-ShareAlike"
      Hydrus::GenericObject.license_human("odc-odbl").should == "ODC-ODbl Open Database License"
    end
  end

  it "augment_identity_metadata() should add correct tags and objectTypes" do
    tests = {
      :collection => '<tag>Hydrus : collection</tag><objectType>set</objectType>',
      :dataset    => '<tag>Hydrus : dataset</tag>',
    }
    tests.each do |object_type, xml|
      exp  = "<identityMetadata>#{xml}</identityMetadata>"
      obj  = Hydrus::GenericObject.new
      idmd = Dor::IdentityMetadataDS.new(nil, nil)
      obj.stub(:identityMetadata).and_return(idmd)
      obj.augment_identity_metadata(object_type)
      idmd.ng_xml.should be_equivalent_to exp
    end
  end

  describe "approve()" do

    it "approve() should dispatch to do_approve() when passed no arguments" do
      @go.should_receive(:do_approve).once
      @go.approve
    end

    it "approve() should dispatch to do_approve() when value is true-ish" do
      tests = ['yes', 'true', true]
      @go.should_receive(:do_approve).exactly(tests.length).times
      tests.each do |v|
        @go.approve('value' => v, 'reason' => 'fooblah')
      end
    end

    it "approve() should dispatch to do_disapprove() when value is false-ish" do
      tests = ['no', 'false', false]
      r = 'fooblah'
      @go.should_receive(:do_disapprove).exactly(tests.length).times.with(r)
      tests.each do |v|
        @go.approve('value' => v, 'reason' => r)
      end
    end

  end

  describe "do_approve()" do

    it "should make expected calls (start_common_assembly = false)" do
      @go.stub(:should_start_common_assembly).and_return(false)
      @go.should_receive(:complete_workflow_step).with('approve').once
      @go.should_not_receive(:initiate_apo_workflow)
      @go.do_approve()
    end

    it "should make expected calls (start_common_assembly = true)" do
      @go.stub(:should_start_common_assembly).and_return(true)
      @go.should_receive(:complete_workflow_step).with('approve').once
      @go.should_receive(:complete_workflow_step).with('start-assembly').once
      @go.should_receive(:initiate_apo_workflow).once
      @go.do_approve()
    end

  end

  it "do_disapprove()" do
    @go.do_disapprove('foo')
    @go.disapproval_reason.should == 'foo'
  end

  describe "workflow stuff" do

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
          <workflow id="accessionWF">
            <process status="waiting" name="publish" lifecycle="published"/>
            <process status="waiting" name="bar"/>
          </workflow>
        </workflows>
      EOXML
      @workflow = Dor::WorkflowDs.from_xml(noko_doc(xml))
      @go = Hydrus::GenericObject.new
      @go.stub(:workflows).and_return(@workflow)
    end

    it "get_workflow_node() should return a node with correct id attribute" do
      node = @go.get_workflow_node
      node.should be_instance_of Nokogiri::XML::Element
      node['id'].should == Dor::Config.hydrus.app_workflow.to_s
    end

    it "get_workflow_step() should return a node with correct name attribute" do
      node = @go.get_workflow_step('approve')
      node.should be_instance_of Nokogiri::XML::Element
      node['name'].should == 'approve'
    end

    it "get_workflow_status() should return the current status of a step" do
      @go.get_workflow_status('start-deposit').should == 'completed'
      @go.get_workflow_status('submit').should        == 'waiting'
      @go.get_workflow_status('blort').should         == nil
    end

    it "workflow_step_is_done() should return correct value" do
      @go.workflow_step_is_done('start-deposit').should == true
      @go.workflow_step_is_done('submit').should        == false
    end

    it "can exercise complete_workflow_step(), stubbed" do
      step = 'submit'
      args = ['dor', @go.pid, kind_of(Symbol), step, 'completed']
      Dor::WorkflowService.should_receive(:update_workflow_status).with(*args)
      @go.complete_workflow_step(step)
    end

    describe "is_published()" do

      it "should return false when submit step is waiting" do
        @go.is_published.should == false
      end

      it "should return true when submit step is completed" do
        @workflow.find_by_xpath('//process[@name="submit"]').first['status'] = 'completed'
        @go.is_published.should == true
      end

      it "should not call workflow_step_is_done() a second time" do
        @go.should_receive(:workflow_step_is_done).once.and_return(false)
        @go.is_published.should == false
        @go.is_published.should == false
      end

    end

    describe "is_approved()" do

      it "should not call workflow_step_is_done() unless the object is published" do
        @go.should_not_receive(:workflow_step_is_done)
        @go.instance_variable_set('@is_published', false)
        @go.is_approved.should == false
      end

      it "should return false if approved step is not completed" do
        @go.stub(:is_published).and_return(true)
        @go.is_approved.should == false
      end

      it "should return true if approved step is completed" do
        @go.stub(:is_published).and_return(true)
        @workflow.find_by_xpath('//process[@name="approve"]').first['status'] = 'completed'
        @go.is_approved.should == true
      end

    end

    it "is_publishable() should return the value of valid?" do
      @go.stub(:pid).and_return('blah')
      @go.valid?.should == false    # Bad PID.
      @go.stub(:pid).and_return('druid:oo000oo0001')
      @go.valid?.should == true     # OK PID.
    end

    it "publish=() should delegate to publish()" do
      v = 9876
      @go.should_receive(:publish).with(v)
      @go.publish= v
    end

    it "approve=() should delegate to approve()" do
      v = 9876
      @go.should_receive(:approve).with(v)
      @go.approve= v
    end

    it "is_disapproved() should return true if disapproval_reason has length" do
      tests = {
        'blah' => true,
        ''     => false,
        nil    => false,
      }
      tests.each do |reason, exp|
        @go.stub(:disapproval_reason).and_return(reason)
        @go.is_disapproved.should == exp
      end
    end

    describe "submit_time()" do

      it "should return nil if Item is unpublished" do
        @go.submit_time.should == nil
      end

      it "should return the datetime of the submit step, but only if step is completed" do
        # Set datetime of step, but don't complete it.
        d = '1999-01-01 00:00:01'
        node = @workflow.find_by_xpath('//process[@name="submit"]').first
        node['datetime'] = d
        @go.submit_time.should == nil
        # Complete the step.
        node['status'] = 'completed'
        @go.submit_time.should == d
      end

    end

    it "publish_lifecycle_time() should return datetime only if published step is completed" do
      # The publish lifecycle not completed yet.
      d = '1999-01-01'
      @go.publish_lifecycle_time().should == nil
      node = @workflow.find_by_xpath('//process[@lifecycle="published"]').first
      # Still not completed, even though we have a datetime.
      node['datetime'] = d
      @go.publish_lifecycle_time().should == nil
      # Complete the step.
      node['status'] = 'completed'
      @go.publish_lifecycle_time().should == d
    end

  end

  describe "should_validate()" do

    it "should not call is_published() when @should_validate is true" do
      @go.instance_variable_set('@should_validate', true)
      @go.should_not_receive(:is_published)
      @go.should_validate.should == true
    end

    it "should return the value of is_published() when @should_validate is false" do
      [false, true].each do |exp|
        @go.stub(:is_published).and_return(exp)
        @go.should_validate.should == exp
      end
    end

  end

  describe "validations" do

    before(:each) do
      @exp = [:pid, :title, :abstract, :contact]
      @go.instance_variable_set('@should_validate', true)
    end

    it "blank slate object (should_validate=false) should include only the :pid error" do
      @go.stub(:should_validate).and_return(false)
      @go.valid?.should == false
      @go.errors.messages.keys.should == [@exp.first]
    end

    it "blank slate object should include all validation errors" do
      @go.valid?.should == false
      @go.errors.messages.should include(*@exp)
    end

    it "fully populated object should be valid" do
      dru = 'druid:ll000ll0001'
      @exp.each { |e| @go.stub(e).and_return(dru) }
      @go.valid?.should == true
    end
  end

  describe "events stuff" do

    before(:each) do
      xml = <<-EOF
        <events>
          <event type="hydrus" who="sunetid:foo" when="2012-08-15T10:11:31-07:00">blah</event>
          <event type="hydrus" who="sunetid:foo" when="2012-08-15T10:12:31-07:00">blort</event>
        </events>
      EOF
      @events = Dor::EventsDS.from_xml(noko_doc(xml))
      @go = Hydrus::GenericObject.new
      @go.stub(:events).and_return(@events)
    end

    it "get_workflow_node() should return a node with correct id attribute" do
      es = @go.get_hydrus_events
      es.size.should == 2
      e = es.first
      e.should be_instance_of Hydrus::Event
      e.type.should == 'hydrus'
      e.who.should  == 'sunetid:foo'
      e.when.year.should  == 2012
      e.when.month.should == 8
      e.when.day.should   == 15
      e.text.should == 'blah'
    end

  end

  it "is_hydrus_item() should work as expected" do
    tests = {
      Hydrus::Item       => true,
      Hydrus::Collection => false,
      String             => false,
    }
    tests.each do |cls, exp|
      @go.stub(:class).and_return(cls)
      @go.is_hydrus_item.should == exp
    end
  end

  it "hydrus_class_to_s() should work as expected" do
    tests = {
      Hydrus::Item       => 'Item',
      Hydrus::Collection => 'Collection',
      String             => 'String',
      Dor::EventsDS      => 'Dor::EventsDS',
    }
    tests.each do |cls, exp|
      @go.stub(:class).and_return(cls)
      @go.hydrus_class_to_s.should == exp
    end
  end

  it "can exercise should_start_common_assembly()" do
    @go.should_start_common_assembly.should == Dor::Config.hydrus.start_common_assembly
  end

  describe "current_user" do

    it "@current_user should be initialized in a lazy fashion" do
      @go.instance_variable_get('@current_user').should == nil
      @go.current_user.should == ''
      @go.instance_variable_get('@current_user').should == ''
    end

    it "can exercise current_user=()" do
      @go.instance_variable_get('@current_user').should == nil
      @go.current_user = 123
      @go.instance_variable_get('@current_user').should == 123
    end

  end

  it "old_self() should call find() with the object's pid" do
    pid = @go.pid
    r = 'blah blah!!'
    Hydrus::GenericObject.should_receive(:find).with(pid).and_return(r)
    @go.old_self.should == r
  end

  it "editing_event_message() should return expected string" do
    fs  = [:foo, :bar, :quux]
    exp = "GenericObject modified: foo, bar, quux"
    @go.editing_event_message(fs).should == exp
  end

  it "changed_fields() should return ..." do
    tf = {
      :a   => [:aa],
      :bb  => [:ba, :bb],
      :ccc => [:ca, :cb, :cc],
      :ddd => [:da, :db],
    }
    @go.stub(:tracked_fields).and_return(tf)
    old = double('old_self')
    exp_diff = [:a, :ccc]
    tf.each do |k,vs|
      vs.each do |v|
        old.stub(v).and_return(v.to_s)
        @go.stub(v).and_return(exp_diff.include?(k) ? 'new_val' : v.to_s)
      end
    end
    @go.stub(:old_self).and_return(old)
    @go.changed_fields.should == exp_diff
  end

  it "GenericObject does not implement tracked_fields()" do
    expect{ @go.tracked_fields }.to raise_error(NoMethodError)
  end

  describe "log_editing_events()" do

    it "should do nothing if there are no changed fields" do
      @go.stub(:changed_fields).and_return([])
      @go.should_not_receive(:events)
      @go.log_editing_events
    end

    it "should add an editing event if there are changed fields" do
      @go.stub(:changed_fields).and_return([:aa, :bb])
      @go.get_hydrus_events.size.should == 0
      @go.log_editing_events
      es = @go.get_hydrus_events
      es.size.should == 1
      es.first.text.should == 'GenericObject modified: aa, bb'
    end

  end

  it "save() should not invoke log_editing_events() if no_edit_logging is true" do
    @go.should_receive(:log_editing_events).once
    @go.save
    @go.save(:no_edit_logging => true)
  end

end