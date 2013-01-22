require 'spec_helper'


describe Hydrus::GenericObject do

  before(:each) do
    @cannot_do_regex = /\ACannot perform action/
    @go      = Hydrus::GenericObject.new
    @apo_pid = 'druid:oo000oo0002'
  end

  it "apo() should return a new blank apo if the apo_pid is nil" do
    @go.apo.class.should == Hydrus::AdminPolicyObject
  end

  it "dru() should return the druid without the prefix" do
    @go.stub(:pid).and_return('druid:oo000oo0003')
    @go.dru.should == 'oo000oo0003'
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
    @go.purl_url.should == "http://purl.stanford.edu/__DO_NOT_USE__"
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
      hgo = Hydrus::GenericObject
      hgo.license_human("cc-by").should == "CC BY Attribution"
      hgo.license_human("cc-by-nc-sa").should == "CC BY-NC-SA Attribution-NonCommercial-ShareAlike"
      hgo.license_human("odc-odbl").should == "ODC-ODbl Open Database License"
      hgo.license_human('blah!!').should =~ /no license/i
    end

  end

  it "augment_identity_metadata() should add correct tags" do
    tests = {
      :collection => '<tag>Hydrus : collection</tag><objectType>set</objectType>',
      :dataset    => '<tag>Hydrus : dataset</tag>',
    }
    tests.each do |item_type, xml|
      exp  = "<identityMetadata>#{xml}</identityMetadata>"
      obj  = Hydrus::GenericObject.new
      idmd = Dor::IdentityMetadataDS.new(nil, nil)
      obj.stub(:identityMetadata).and_return(idmd)
      obj.augment_identity_metadata(item_type)
      idmd.ng_xml.should be_equivalent_to exp
    end
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
      node = @go.workflows.get_workflow_node
      node.should be_instance_of Nokogiri::XML::Element
      node['id'].should == Dor::Config.hydrus.app_workflow.to_s
    end

    it "get_workflow_step() should return a node with correct name attribute" do
      node = @go.workflows.get_workflow_step('approve')
      node.should be_instance_of Nokogiri::XML::Element
      node['name'].should == 'approve'
    end

    it "get_workflow_status() should return the current status of a step" do
      @go.workflows.get_workflow_status('start-deposit').should == 'completed'
      @go.workflows.get_workflow_status('submit').should        == 'waiting'
      @go.workflows.get_workflow_status('blort').should         == nil
    end

    it "workflow_step_is_done() should return correct value" do
      @go.workflows.workflow_step_is_done('start-deposit').should == true
      @go.workflows.workflow_step_is_done('submit').should        == false
    end

    describe "complete_workflow_step()" do

      it "should do nothing if the step is already completed" do
        Dor::WorkflowService.should_not_receive(:update_workflow_status)
        @go.stub_chain(:workflows, :workflow_step_is_done).and_return(true)
        @go.complete_workflow_step('foo')
      end

      it "can exercise the method, stubbing out call to WF service" do
        step = 'submit'
        args = ['dor', @go.pid, kind_of(Symbol), step, 'completed']
        Dor::WorkflowService.should_receive(:update_workflow_status).with(*args)
        @go.stub_chain(:workflows, :workflow_step_is_done).and_return(false)
        @go.should_receive(:workflows_content_is_stale)
        @go.complete_workflow_step(step)
      end

    end

    it "can exercise uncomplete_workflow_steps() stubbed" do
      @go.should_receive(:update_workflow_status).exactly(3).times
      @go.uncomplete_workflow_steps()
    end

    it "can exercise workflows_content_is_stale, stubbed" do
      @go.workflows.should_receive(:instance_variable_set).twice
      @go.workflows_content_is_stale
    end

    it "is_published() should return true if object status is any flavor of publish" do
      tests = {
        'published'         => true,
        'published_open'    => true,
        'published_closed'  => true,
        'draft'             => false,
        'awaiting_approval' => false,
      }
      tests.each do |status, exp|
        @go.stub(:object_status).and_return(status)
        @go.is_published.should == exp
      end
    end

  end

  describe "validations" do

    before(:each) do
      @exp = [:pid, :contact]
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

    it "fully populated object should not be valid if contact email is invalid" do
      dru = 'druid:ll000ll0001'
      @exp.each { |e| @go.stub(e).and_return(dru)}
      @go.valid?.should == false
    end

    it "fully populated object should be valid if contact email is valid" do
      dru = 'druid:ll000ll0001'
      @exp.each { |e| @go.stub(e).and_return(dru) unless e==:contact}
      @go.stub(:contact).and_return('test@test.com')
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

  describe "start_common_assembly()" do

    it "should do nothing if the app is not configured to start common assembly" do
      @go.stub(:should_start_common_assembly).and_return(false)
      @go.should_not_receive(:update_content_metadata)
      @go.should_not_receive(:complete_workflow_step)
      @go.start_common_assembly
    end

    it "should raise exception if the object is not assemblable" do
      @go.stub(:should_start_common_assembly).and_return(true)
      @go.stub(:is_assemblable).and_return(false)
      expect { @go.start_common_assembly }.to raise_exception(@cannot_do_regex)
    end

    it "can exercise the method, stubbed" do
      @go.stub(:should_start_common_assembly).and_return(true)
      @go.stub(:is_assemblable).and_return(true)
      @go.should_receive(:update_content_metadata).once
      @go.should_receive(:complete_workflow_step).once
      Dor::WorkflowService.should_receive(:create_workflow).once
      @go.start_common_assembly
    end

  end

  it "can exercise should_start_common_assembly()" do
    @go.should_start_common_assembly.should == Dor::Config.hydrus.start_common_assembly
  end

  it "publish_metadata() should do nothing if app is not configured to start common assembly" do
    @go.stub(:should_start_common_assembly).and_return(false)
    @go.should_not_receive(:is_assemblable)
    @go.publish_metadata
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

  describe "object returned email" do
    it "should provide a method to send object returned emails" do
      @go.stub(:recipients_for_object_returned_email).and_return('jdoe')
      @go.stub(:object_type=>'item')
      mail = @go.send_object_returned_email_notification(:item_url=>'/fake/it')
      mail.to.should == ["jdoe@stanford.edu"]
      mail.subject.should =~ /Item returned in the Stanford Digital Repository/
    end
    it "should return nil when no recipients are sent in" do
      @go.stub(:recipients_for_object_returned_email).and_return('')
      @go.send_object_returned_email_notification.should be_nil
    end
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

  describe "save()" do

    it "should invoke log_editing_events() usually" do
      @go.should_receive(:log_editing_events).once
      @go.should_not_receive(:publish_metadata)
      @go.save(:no_super => true)
    end

    it "should not invoke log_editing_events() if no_edit_logging is true" do
      @go.should_not_receive(:publish_metadata)
      @go.should_not_receive(:log_editing_events)
      @go.save(:no_edit_logging => true, :no_super => true)
    end

    it "should not invoke log_editing_events() if no_edit_logging is true" do
      @go.should_receive(:log_editing_events).once
      @go.should_receive(:publish_metadata).once
      @go.stub('is_collection?').and_return(true)
      @go.stub(:is_published).and_return(true)
      @go.save(:no_super => true)
    end

  end

  it "is_item? and is_collection? should work" do
    hi = Hydrus::Item.new
    hc = Hydrus::Collection.new
    go = @go
    hi.is_item?.should == true
    hc.is_item?.should == false
    go.is_item?.should == false
    hi.is_collection?.should == false
    hc.is_collection?.should == true
    go.is_collection?.should == false
  end

  it "can exercise status_label()" do
    tests = {
      'draft'          => 'draft',
      'published_open' => 'published',
      'published'      => 'published',
      'returned'       => 'item returned',
    }
    tests.each do |status, exp|
      @go.stub(:object_status).and_return(status)
      @go.status_label.should == exp
    end
  end

  it "can exercise Hydrus::GenericObject.status_labels()" do
    tests = [:collection, :item]
    tests.each do |k|
      Hydrus::GenericObject.status_labels(k).should be_instance_of Hash
    end
  end

  it "cannot_do() should raise an exception" do
    expect { @go.cannot_do(:foo) }.to raise_error(/^Cannot perform action.+=foo/)
  end

  describe "XML beautification" do

    before(:each) do
      @orig_xml = '
        <foo>
              <bar>Blah</bar>    <quux>Hello</quux>
          <quux>World</quux></foo>
      '
      @exp = [
        '<?xml version="1.0"?>',
        '<foo>',
        '  <bar>Blah</bar>',
        '  <quux>Hello</quux>',
        '  <quux>World</quux>',
        '</foo>',
        '',
      ].join("\n")
    end

    it "beautified_xml()" do
      @go.beautified_xml(@orig_xml).should == @exp
    end

    it "beautify_datastream()" do
      @go.descMetadata.content = @orig_xml
      @go.descMetadata.content.should == @orig_xml
      @go.beautify_datastream(:descMetadata)
      @go.descMetadata.content.should == @exp
    end

  end

  it "related_item_url=() and related_item_title=()" do
    # Initial state.
    @go.related_item_title.should == ['']
    @go.related_item_url.should == ['']
    # Assign a single value.
    @go.related_item_title = 'Z'
    @go.related_item_url = 'foo'
    @go.related_item_title.should == ['Z']
    @go.related_item_url.should == ['http://foo']
    # Add two mode nodes.
    @go.descMetadata.insert_related_item
    @go.descMetadata.insert_related_item
    # Set using hashes.
    @go.related_item_title = {'0' => 'A', '1' => 'B', '2' => 'C'}
    @go.related_item_url   = {'0' => 'boo', '1' => 'bar', '2' => 'ftp://quux'}
    @go.related_item_title.should == %w(A B C)
    @go.related_item_url.should == ['http://boo', 'http://bar', 'ftp://quux']
    # Also confirm that each title and URL is put in its own relatedItem node.
    # We had bugs causing them to be put all in the first node.
    ri_nodes = @go.descMetadata.find_by_terms(:relatedItem)
    ri_nodes.size.should == 3
    ri_nodes.each do |nd|
      nd = Nokogiri::XML(nd.to_s, &:noblanks)  # Generic XML w/o namespaces.
      nd.xpath('//title').size.should == 1
      nd.xpath('//url').size.should == 1
    end
  end

  it "with_protocol()" do
    f = 'http://foo'
    b = 'http://bar'
    q = 'ftp://quux'
    tests = {
      'foo' => f,
      b     => b,
      q     => q,
      ''    => '',
      nil   => nil,
    }
    tests.each do |uri, exp|
      @go.with_protocol(uri).should == exp
    end

  end

end
