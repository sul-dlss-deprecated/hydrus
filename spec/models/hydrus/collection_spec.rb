require 'spec_helper'

describe Hydrus::Collection do

  before(:each) do
    @hc = Hydrus::Collection.new
  end

  it "can exercise a stubbed version of create()" do
    # Note: more substantive testing is done at integration level.
    Hydrus::Authorizable.stub(:can_create_collections).and_return(true)
    # Stub out the APO create() method.
    apo = Hydrus::AdminPolicyObject.new
    Hydrus::AdminPolicyObject.stub(:create).and_return(apo)
    # Set up a collection for use when stubbing register_dor_object().
    druid = 'druid:BLAH'
    stubs = [
      :remove_relationship,
      :assert_content_model,
      :augment_identity_metadata,
    ]
    stubs.each { |s| @hc.should_receive(s) }
    @hc.should_receive(:save).with(:no_edit_logging => true, :no_beautify => true)
    @hc.stub(:pid).and_return(druid)
    @hc.stub(:adapt_to).and_return(@hc)
    Hydrus::GenericObject.stub(:register_dor_object).and_return(@hc)
    # Call create().
    obj = Hydrus::Collection.create('USERFOO')
    obj.pid.should == druid
    obj.get_hydrus_events.size.should == 1
    obj.terms_of_use.should =~ /user agrees/i
  end

  describe "open() and close()" do

    # More substantive testing is done at integration level.

    before(:each) do
      apo_druid = 'druid:oo000oo9991'
      apo = Hydrus::AdminPolicyObject.new(:pid => apo_druid)
      @hc.stub(:apo).and_return(apo)
    end

    it "open() should set object_status, add event, call approve" do
      hc_title      = 'blah blah blah'
      apo_title     = "APO for #{hc_title}"
      @hc.title     = hc_title
      @hc.apo.title = apo_title
      @hc.get_hydrus_events.size.should == 0
      @hc.should_receive(:complete_workflow_step).exactly(3).times
      @hc.apo.should_receive(:complete_workflow_step).exactly(3).times
      @hc.should_receive(:start_assembly_wf).once
      @hc.should_receive(:send_publish_email_notification).once.with(true)
      @hc.stub(:is_openable).and_return(true)
      @hc.stub(:is_draft).and_return(true)
      @hc.stub(:is_assemblable).and_return(true)
      @hc.open
      @hc.get_hydrus_events.size.should > 0
      @hc.apo.identityMetadata.objectLabel.should == [apo_title]
      @hc.apo.title.should                        == apo_title
      @hc.identityMetadata.objectLabel.should     == [hc_title]
      @hc.label.should                            == hc_title
      @hc.apo.label.should                        == apo_title
      @hc.publish_time.should_not be_blank
    end

    it "close() should set object_status and add an event" do
      @hc.get_hydrus_events.size.should == 0
      @hc.should_not_receive(:approve)
      @hc.should_receive(:send_publish_email_notification).once.with(false)
      @hc.stub(:is_closeable).and_return(true)
      @hc.close
      @hc.get_hydrus_events.size.should > 0
    end

    it "should raise exceptions if the object cannot be opened/closed" do
      tests = {
        :open  => :is_openable,
        :close => :is_closeable,
      }
      tests.each do |meth, predicate|
        @hc.stub(predicate).and_return(false)
        expect { @hc.send(meth) }.to raise_error
      end
    end

  end

  describe "valid?()" do

    before(:each) do
      @apo = Hydrus::AdminPolicyObject.new
      @hc.stub(:apo).and_return(@apo)
      @hc.stub(:should_validate).and_return(true)
      @exp_errs = [
        :title,
        :abstract,
        :contact,
        :embargo,
        :embargo_option,
        :license_option,
      ]
      @dru = 'druid:oo000oo9999'
    end

    it "should validate both Collection and its APO, and merge their errors" do
      # Give Collection a valid pid.
      @hc.stub(:pid).and_return(@dru)
      # Collection error messages should include :pid, which came from the APO.
      @hc.valid?.should == false
      es = @hc.errors.messages
      es.should include(:pid)
    end

    it "should get only the Collection errors when the APO is valid" do
      # Give Collection a valid pid, and stub the APO as valid.
      @hc.stub(:pid).and_return(@dru)
      @apo.stub(:'valid?').and_return(true)
      # Collection errors should not include PID, but should include the rest.
      @hc.valid?.should == false
      es = @hc.errors.messages
      es.should_not include(:pid)
      es.should     include(*@exp_errs)
    end

    it "should return true when both Collection and APO are valid" do
      @exp_errs.each { |e| @hc.stub(e).and_return(@dru) unless e==:contact }
      @hc.stub(:contact).and_return('test@test.com') # we need a valid email address
      @hc.stub(:embargo_terms).and_return(@dru)
      @hc.stub(:pid).and_return(@dru)
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

  it "is_open() should return true if the collection is open for deposit" do
    tests = {
      'published_open' => true,
      'published'      => false,
      'draft'          => false,
      nil              => false,
    }
    tests.each do |status, exp|
      @hc.stub(:object_status).and_return(status)
      @hc.is_open.should == exp
    end
  end

  describe "is_openable()" do

    it "collection already open: should return false no matter what" do
      @hc.stub('validate!').and_return(true)
      @hc.stub(:object_status).and_return('published_open')
      @hc.is_openable.should == false  # False in spite of being valid.
    end

    it "collection not open: should return true if valid" do
      @hc.stub(:is_open).and_return(false)
      [true, false, true].each do |exp|
        @hc.stub('validate!').and_return(exp)
        @hc.is_openable.should == exp
      end
    end

  end

  it "is_closeable() should return the value of is_open()" do
    [true, false, true].each do |exp|
      @hc.stub(:is_open).and_return(exp)
      @hc.is_closeable.should == exp
    end
  end

  describe "is_assemblable()" do

    it "closed collection: should always return false" do
      @hc.stub(:is_open).and_return(false)
      @hc.should_not_receive('validate!')
      @hc.is_assemblable.should == false
    end

    it "published item: should return value of validate!" do
      @hc.stub(:is_open).and_return(true)
      [true, false].each do |exp|
        @hc.stub('validate!').and_return(exp)
        @hc.is_assemblable.should == exp
      end
    end

  end

  describe "invite email" do
    it "should provide a method to send deposit invites" do
      mail = @hc.send_invitation_email_notification("jdoe")
      mail.to.should == ["jdoe@stanford.edu"]
      mail.subject.should =~ /Invitation to deposit in the Stanford Digital Repository/
    end
    it "should return nil when no recipients are sent in" do
      @hc.send_invitation_email_notification("").should be_nil
    end
  end

  describe "open/close notification email" do
    it "should provide a method to send open notification emails" do
      @hc.stub(:recipients_for_collection_update_emails).and_return('jdoe')
      mail = @hc.send_publish_email_notification(true)
      mail.to.should == ["jdoe@stanford.edu"]
      mail.subject.should =~ /Collection opened for deposit in the Stanford Digital Repository/
    end
    it "should provide a method to send close notification emails" do
      @hc.stub(:recipients_for_collection_update_emails).and_return('jdoe')
      mail = @hc.send_publish_email_notification(false)
      mail.to.should == ["jdoe@stanford.edu"]
      mail.subject.should =~ /Collection closed for deposit in the Stanford Digital Repository/
    end
    it "should return nil when no recipients are set" do
      @hc.stub(:recipients_for_collection_update_emails).and_return('')
      @hc.send_publish_email_notification(true).should be_nil
      @hc.send_publish_email_notification(false).should be_nil
    end
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
          <role type="hydrus-collection-item-depositor">
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
          <role type="hydrus-collection-item-depositor">
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
          <role type="hydrus-collection-item-depositor">
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
        'hydrus-collection-manager' => 'archivist4, archivist5',
        'hydrus-collection-item-depositor'     => 'archivist6',
      }
      @rmdoc.ng_xml.should be_equivalent_to <<-EOF
        <roleMetadata>
          <role type="hydrus-collection-manager">
            <person><identifier type="sunetid">archivist4</identifier><name/></person>
            <person><identifier type="sunetid">archivist5</identifier><name/></person>
          </role>
          <role type="hydrus-collection-item-depositor">
            <person><identifier type="sunetid">archivist6</identifier><name/></person>
          </role>
        </roleMetadata>
      EOF
    end

    it "apo_person_roles should forward to apo.person_roles" do
      apo = Hydrus::AdminPolicyObject.new
      @hc.stub(:apo).and_return(apo)
      apo.should_receive(:person_roles)
      @hc.apo_person_roles
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

  it "cleaned_usernames() should process the apo_person_roles info as expected" do
    apr = {
      'role1' => Set.new(%w(foo bar@blah quux@blah.edu)),
      'role2' => Set.new(%w(abc@def xyz www@stanford.edu)),
    }
    exp = {
      'role1' => 'foo,bar,quux',
      'role2' => 'abc,xyz,www',
    }
    @hc.stub(:apo_person_roles).and_return(apr)
    @hc.cleaned_usernames.should == exp
  end

  describe "getters and setters" do

    before(:each) do
      @arg = 'foobar'
    end

    describe "embargo/license conditional getters and setters" do

      before(:each) do
        @combos = [
          %w(embargo fixed embargo_terms),
          %w(embargo varies embargo_terms),
          %w(license fixed license),
          %w(license varies license),
        ]
      end

      it "FOO_VAL() should return FOO() if FOO_option() returns VAL" do
        @combos.each do |typ, val, att|
          # Example:
          #   FOO_VAL()     embargo_fixed()
          #   FOO_option()  embargo_option()
          #   FOO()         embargo()
          #   VAL           'fixed'
          # Initially, FOO_VAL() returns empty string.
          m = "#{typ}_#{val}".to_sym
          @hc.send(m).should == ''
          # And if FOO_option() returns VAL, then FOO_VAL() will return FOO().
          exp = 'blah blah!!'
          @hc.stub("#{typ}_option").and_return(val)
          @hc.stub(att).and_return(exp)
          @hc.send(m).should == exp
        end
      end

      it "setters should not call FOO= because FOO_option() does not return VAL" do
        @combos.each do |typ, val, att|
          m = "#{typ}="
          @hc.should_not_receive(m)
          @hc.stub("#{typ}_option").and_return('')
          @hc.send("#{typ}_#{val}=", 'new_val')
        end
      end

      it "setters should call FOO= because FOO_option() does return VAL" do
        @combos.each do |typ, val, att|
          m   = "#{att}="
          exp = 'new value!'
          @hc.should_receive(m).with(exp).once
          @hc.stub("#{typ}_option").and_return(val)
          @hc.send("#{typ}_#{val}=", exp)
        end
      end

    end

    describe "visibility_option_value getter and setter" do

      it "can exercise the getter" do
        @hc.stub(:visibility_option).and_return('fixed')
        @hc.stub(:visibility).and_return(['world'])
        @hc.visibility_option_value.should == 'everyone'
      end

      it "the setter should call the expected setters" do
        @hc.should_receive('visibility_option=').with('fixed')
        @hc.should_receive('visibility=').with('world')
        @hc.visibility_option_value = 'everyone'
      end

    end

    describe "visibility getter and setter" do

      it "getter should return ['world'] if item is world visible" do
        @hc.stub_chain(:rightsMetadata, :has_world_read_node).and_return(true)
        @hc.visibility.should == ['world']
      end

      it "getter should return groups names if item is not world visible" do
        exp_groups = %w(foo bar)
        mock_nodes = exp_groups.map { |g| double('', :text => g) }
        @hc.stub_chain(:rightsMetadata, :has_world_read_node).and_return(false)
        @hc.stub_chain(:rightsMetadata, :group_read_nodes).and_return(mock_nodes)
        @hc.visibility.should == exp_groups
      end

      it "the setter should call the expected setters" do
        @hc.should_receive('visibility_option=').with('fixed')
        @hc.should_receive('visibility=').with('world')
        @hc.visibility_option_value = 'everyone'
      end

    end

  end

  describe "dashboard stats and related methods" do

    before(:all) do
      @HC       = Hydrus::Collection
      @user_foo = 'user_foo'
    end

    describe "dashboard_stats()" do

      it "should return empty hash if there are no APOs involving the user" do
        @HC.should_receive(:apos_involving_user).and_return([])
        @HC.should_not_receive(:collections_of_apos)
        @HC.dashboard_stats(@user_foo).should == {}
      end

      it "should return empty hash if there are no Collections involving the user" do
        @HC.should_receive(:apos_involving_user).and_return([1,2,3])
        @HC.should_receive(:collections_of_apos).and_return([])
        @HC.should_not_receive(:item_counts_of_collections)
        @HC.dashboard_stats(@user_foo).should == {}
      end

      it "should return item_counts_of_collections() if there are relevant Collections" do
        exp = {:foo => 1, :bar => 2}
        @HC.should_receive(:apos_involving_user).and_return([1,2,3])
        @HC.should_receive(:collections_of_apos).and_return([4,5,6])
        @HC.should_receive(:item_counts_of_collections).and_return(exp)
        @HC.dashboard_stats(@user_foo).should == exp
      end

    end

    it "can exercise initial_item_counts()" do
      h = @HC.initial_item_counts()
      h.should be_instance_of(Hash)
      h.values.should == [0,0,0,0]
    end

    it "can exercise methods returning APO and Collection druids" do
      resp = double('mock_response')
      exp  = 12345
      @HC.stub(:issue_solr_query).and_return([resp, nil])
      @HC.should_receive(:get_druids_from_response).with(resp).exactly(3).and_return(exp)
      @HC.apos_involving_user(@user_foo).should == exp
      @HC.collections_of_apos([1,2,3,4]).should == exp
      @HC.all_hydrus_collections.should == exp
    end

    it "can exercise get_druids_from_response()" do
      k    = 'identityMetadata_objectId_t'
      exp  = [12, 34, 56]
      docs = exp.map { |n| {k => [n]} }
      resp = double('resp', :docs => docs)
      @HC.get_druids_from_response(resp).should == exp
    end

    it "can exercise get_facet_counts_from_response()" do
      exp  = 1234
      fcs  = {'facet_pivot' => {:a => exp}}
      resp = double('resp', :facet_counts => fcs)
      @HC.get_facet_counts_from_response(resp).should == exp
    end

    it "can exercise item_counts_with_labels()" do
      cs = {
          "draft"             => 1,
          "awaiting_approval" => 2,
          "returned"          => 3,
          "published"         => 4,
      }
      @hc.stub(:item_counts).and_return(cs)
      exp = [
        [1, "draft"],
        [2, "waiting for approval"],
        [3, "item returned"],
        [4, "published"],
      ]
      @hc.item_counts_with_labels.should == exp
    end

    it "item_counts_of_collections()" do
      exp = {
        "druid:xx000xx0001" => {
          "awaiting_approval" => 2,
          "returned"          => 3,
          "published"         => 4,
        },
        "druid:xx000xx0002" => {
          "draft"             => 14,
          "awaiting_approval" => 15,
          "returned"          => 16,
          "published"         => 17,
        },
        "druid:xx000xx0003" => {},
      }
      coll_pids = exp.keys
      fcs = [
        {
          "value" => "info:fedora/#{coll_pids[0]}",
          "pivot" => [
            { "value" => "draft",             "count" => 0 },
            { "value" => "awaiting_approval", "count" => 2 },
            { "value" => "returned",          "count" => 3 },
            { "value" => "published",         "count" => 4 },
          ],
        },
        {
          "value" => "info:fedora/#{coll_pids[1]}",
          "pivot" => [
            { "value" => "draft",             "count" => 14 },
            { "value" => "awaiting_approval", "count" => 15 },
            { "value" => "returned",          "count" => 16 },
            { "value" => "published",         "count" => 17 },
          ],
        },
      ]
      @HC.stub(:issue_solr_query).and_return([nil, nil])
      @HC.stub(:get_facet_counts_from_response).and_return(fcs)
      @HC.item_counts_of_collections(coll_pids).should == exp
    end

  end

end
