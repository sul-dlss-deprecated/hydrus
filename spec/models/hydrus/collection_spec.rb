require 'spec_helper'

RSpec.describe Hydrus::Collection, type: :model do
  before do
    @hc = Hydrus::Collection.new
  end

  describe 'save()' do
    context 'on an existing object when no_edit_logging is false' do
      before do
        allow(@hc).to receive('is_collection?').and_return(true)
        allow(@hc).to receive(:is_published).and_return(true)
        allow(@hc).to receive(:is_open).and_return(true)
        allow(@hc).to receive(:new_record?).and_return(false)
      end
      it 'invokes log_editing_events()' do
        expect(@hc).to receive(:log_editing_events).once
        expect(@hc).to receive(:publish_metadata).once
        @hc.save(no_super: true)
      end
    end
  end

  describe 'open() and close()' do
    # More substantive testing is done at integration level.

    before(:each) do
      apo_druid = 'druid:oo000oo9991'
      apo = Hydrus::AdminPolicyObject.new(pid: apo_druid)
      allow(@hc).to receive(:apo).and_return(apo)
    end

    it 'open() should set object_status, add event, call approve' do
      hc_title      = 'blah blah blah'
      apo_title     = "APO for #{hc_title}"
      @hc.title     = hc_title
      @hc.apo.title = apo_title
      expect(@hc.get_hydrus_events.size).to eq(0)
      expect(@hc).to receive(:complete_workflow_step).exactly(3).times
      expect(@hc.apo).to receive(:complete_workflow_step).exactly(3).times
      expect(@hc).to receive(:start_assembly_wf).once
      expect(@hc).to receive(:send_publish_email_notification).once.with(true)
      allow(@hc).to receive(:is_openable).and_return(true)
      allow(@hc).to receive(:is_draft).and_return(true)
      allow(@hc).to receive(:is_assemblable).and_return(true)
      @hc.open
      expect(@hc.get_hydrus_events.size).to be > 0
      expect(@hc.apo.identityMetadata.objectLabel).to eq([apo_title])
      expect(@hc.apo.title).to                        eq(apo_title)
      expect(@hc.identityMetadata.objectLabel).to     eq([hc_title])
      expect(@hc.label).to                            eq(hc_title)
      expect(@hc.apo.label).to                        eq(apo_title)
      expect(@hc.submitted_for_publish_time).not_to be_blank
      expect(@hc.initial_submitted_for_publish_time).not_to be_blank
    end

    it 'close() should set object_status and add an event' do
      expect(@hc.get_hydrus_events.size).to eq(0)
      expect(@hc).not_to receive(:approve)
      expect(@hc).to receive(:send_publish_email_notification).once.with(false)
      allow(@hc).to receive(:is_closeable).and_return(true)
      @hc.close
      expect(@hc.get_hydrus_events.size).to be > 0
    end

    it 'should raise exceptions if the object cannot be opened/closed' do
      tests = {
        open: :is_openable,
        close: :is_closeable,
      }
      tests.each do |meth, predicate|
        allow(@hc).to receive(predicate).and_return(false)
        expect { @hc.send(meth) }.to raise_error(RuntimeError)
      end
    end
  end

  describe 'valid?()' do
    before(:each) do
      @apo = Hydrus::AdminPolicyObject.new
      allow(@hc).to receive(:apo).and_return(@apo)
      allow(@hc).to receive(:should_validate).and_return(true)
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

    it 'should validate both Collection and its APO, and merge their errors' do
      # Give Collection a valid pid.
      allow(@hc).to receive(:pid).and_return(@dru)
      # Collection error messages should include :pid, which came from the APO.
      expect(@hc.valid?).to eq(false)
      es = @hc.errors.messages
      expect(es).to include(:pid)
    end

    it 'should get only the Collection errors when the APO is valid' do
      # Give Collection a valid pid, and stub the APO as valid.
      allow(@hc).to receive(:pid).and_return(@dru)
      allow(@apo).to receive(:'valid?').and_return(true)
      # Collection errors should not include PID, but should include the rest.
      expect(@hc.valid?).to eq(false)
      es = @hc.errors.messages
      expect(es).not_to include(:pid)
      expect(es).to     include(*@exp_errs)
    end

    it 'should return true when both Collection and APO are valid' do
      @exp_errs.each { |e| allow(@hc).to receive(e).and_return(@dru) unless e == :contact }
      allow(@hc).to receive(:contact).and_return('test@test.com') # we need a valid email address
      allow(@hc).to receive(:embargo_terms).and_return(@dru)
      allow(@hc).to receive(:pid).and_return(@dru)
      allow(@apo).to receive(:'valid?').and_return(true)
      expect(@hc.valid?).to eq(true)
    end
  end

  it 'is_destroyable() should return true only if Collection is unpublished with 0 Items' do
    tests = [
      [false, false, true],
      [false, true,  false],
      [true,  false, false],
      [false, false, true],
    ]
    tests.each do |is_p, has_i, exp|
      allow(@hc).to receive(:is_published).and_return(is_p)
      allow(@hc).to receive(:has_items).and_return(has_i)
      expect(@hc.is_destroyable).to eq(exp)
    end
  end

  it 'has_items() should return true only if Collection has Items' do
    allow(@hc).to receive(:hydrus_items).and_return([])
    allow(@hc).to receive(:items).and_return([])
    expect(@hc.has_items).to eq(false)
    allow(@hc).to receive(:hydrus_items).and_return([0, 11, 22])
    allow(@hc).to receive(:items).and_return([0, 11, 22])
    expect(@hc.has_items).to eq(true)
  end

  it 'is_open() should return true if the collection is open for deposit' do
    tests = {
      'published_open' => true,
      'published'      => false,
      'draft'          => false,
      nil              => false,
    }
    tests.each do |status, exp|
      allow(@hc).to receive(:object_status).and_return(status)
      expect(@hc.is_open).to eq(exp)
    end
  end

  describe 'is_openable()' do
    it 'collection already open: should return false no matter what' do
      allow(@hc).to receive('validate!').and_return(true)
      allow(@hc).to receive(:object_status).and_return('published_open')
      expect(@hc.is_openable).to eq(false) # False in spite of being valid.
    end

    it 'collection not open: should return true if valid' do
      allow(@hc).to receive(:is_open).and_return(false)
      [true, false, true].each do |exp|
        allow(@hc).to receive('validate!').and_return(exp)
        expect(@hc.is_openable).to eq(exp)
      end
    end
  end

  it 'is_closeable() should return the value of is_open()' do
    [true, false, true].each do |exp|
      allow(@hc).to receive(:is_open).and_return(exp)
      expect(@hc.is_closeable).to eq(exp)
    end
  end

  describe 'is_assemblable()' do
    it 'closed collection: should always return false' do
      allow(@hc).to receive(:is_open).and_return(false)
      expect(@hc).not_to receive('validate!')
      expect(@hc.is_assemblable).to eq(false)
    end

    it 'published item: should return value of validate!' do
      allow(@hc).to receive(:is_open).and_return(true)
      [true, false].each do |exp|
        allow(@hc).to receive('validate!').and_return(exp)
        expect(@hc.is_assemblable).to eq(exp)
      end
    end
  end

  describe 'invite email' do
    it 'should provide a method to send deposit invites' do
      mail = @hc.send_invitation_email_notification('jdoe')
      expect(mail.to).to eq(['jdoe@stanford.edu'])
      expect(mail.subject).to match(/Invitation to deposit in the Stanford Digital Repository/)
    end
    it 'should return nil when no recipients are sent in' do
      expect(@hc.send_invitation_email_notification('')).to be_nil
    end
  end

  describe 'open/close notification email' do
    it 'should provide a method to send open notification emails' do
      allow(@hc).to receive(:recipients_for_collection_update_emails).and_return('jdoe')
      mail = @hc.send_publish_email_notification(true)
      expect(mail.to).to eq(['jdoe@stanford.edu'])
      expect(mail.subject).to match(/Collection opened for deposit in the Stanford Digital Repository/)
    end
    it 'should provide a method to send close notification emails' do
      allow(@hc).to receive(:recipients_for_collection_update_emails).and_return('jdoe')
      mail = @hc.send_publish_email_notification(false)
      expect(mail.to).to eq(['jdoe@stanford.edu'])
      expect(mail.subject).to match(/Collection closed for deposit in the Stanford Digital Repository/)
    end
    it 'should return nil when no recipients are set' do
      allow(@hc).to receive(:recipients_for_collection_update_emails).and_return('')
      expect(@hc.send_publish_email_notification(true)).to be_nil
      expect(@hc.send_publish_email_notification(false)).to be_nil
    end
  end

  context 'APO roleMetadataDS delegation-y methods' do
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
      allow(apo).to receive(:roleMetadata).and_return(@rmdoc)

      @hc = Hydrus::Collection.new
      allow(@hc).to receive(:apo).and_return(apo)
    end

    it 'add_empty_person_to_role should work' do
      @hc.add_empty_person_to_role('hydrus-collection-manager')
      expect(@rmdoc.ng_xml).to be_equivalent_to <<-EOF
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
      expect(@rmdoc.ng_xml).to be_equivalent_to <<-EOF
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

    it 'apo_person_roles= should correctly update APO roleMetadtaDS' do
      @hc.apo_person_roles = {
        'hydrus-collection-manager' => 'archivist4, archivist5',
        'hydrus-collection-item-depositor' => 'archivist6',
      }
      expect(@rmdoc.ng_xml).to be_equivalent_to <<-EOF
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

    it 'apo_person_roles should forward to apo.person_roles' do
      apo = Hydrus::AdminPolicyObject.new
      allow(@hc).to receive(:apo).and_return(apo)
      expect(apo).to receive(:person_roles)
      @hc.apo_person_roles
    end

    it 'apo_persons_with_role() should delegate to apo.persons_with_role()' do
      role = 'foo_role'
      apo = double('apo')
      expect(apo).to receive(:persons_with_role).with(role)
      allow(@hc).to receive(:apo).and_return(apo)
      @hc.apo_persons_with_role(role)
    end
  end

  it 'can exercise tracked_fields()' do
    expect(@hc.tracked_fields).to be_an_instance_of(Hash)
  end

  it 'cleaned_usernames() should process the apo_person_roles info as expected' do
    apr = {
      'role1' => Set.new(%w(foo bar@blah quux@blah.edu)),
      'role2' => Set.new(%w(abc@def xyz www@stanford.edu)),
    }
    exp = {
      'role1' => 'foo,bar,quux',
      'role2' => 'abc,xyz,www',
    }
    allow(@hc).to receive(:apo_person_roles).and_return(apr)
    expect(@hc.cleaned_usernames).to eq(exp)
  end

  describe 'getters and setters' do
    before(:each) do
      @arg = 'foobar'
    end

    describe 'embargo/license conditional getters and setters' do
      before(:each) do
        @combos = [
          %w(embargo fixed embargo_terms),
          %w(embargo varies embargo_terms),
          %w(license fixed license),
          %w(license varies license),
        ]
      end

      it 'FOO_VAL() should return FOO() if FOO_option() returns VAL' do
        @combos.each do |typ, val, att|
          # Example:
          #   FOO_VAL()     embargo_fixed()
          #   FOO_option()  embargo_option()
          #   FOO()         embargo()
          #   VAL           'fixed'
          # Initially, FOO_VAL() returns empty string.
          m = "#{typ}_#{val}".to_sym
          expect(@hc.send(m)).to eq('')
          # And if FOO_option() returns VAL, then FOO_VAL() will return FOO().
          exp = 'blah blah!!'
          allow(@hc).to receive("#{typ}_option").and_return(val)
          allow(@hc).to receive(att).and_return(exp)
          expect(@hc.send(m)).to eq(exp)
        end
      end

      it 'setters should not call FOO= because FOO_option() does not return VAL' do
        @combos.each do |typ, val, att|
          m = "#{typ}="
          expect(@hc).not_to receive(m)
          allow(@hc).to receive("#{typ}_option").and_return('')
          @hc.send("#{typ}_#{val}=", 'new_val')
        end
      end

      it 'setters should call FOO= because FOO_option() does return VAL' do
        @combos.each do |typ, val, att|
          m   = "#{att}="
          exp = 'new value!'
          expect(@hc).to receive(m).with(exp).once
          allow(@hc).to receive("#{typ}_option").and_return(val)
          @hc.send("#{typ}_#{val}=", exp)
        end
      end
    end

    describe 'visibility_option_value getter and setter' do
      it 'can exercise the getter' do
        allow(@hc).to receive(:visibility_option).and_return('fixed')
        allow(@hc).to receive(:visibility).and_return(['world'])
        expect(@hc.visibility_option_value).to eq('everyone')
      end

      it 'the setter should call the expected setters' do
        expect(@hc).to receive('visibility_option=').with('fixed')
        expect(@hc).to receive('visibility=').with('world')
        @hc.visibility_option_value = 'everyone'
      end
    end

    describe 'visibility getter and setter' do
      it "getter should return ['world'] if item is world visible" do
        allow(@hc).to receive_message_chain(:rightsMetadata, :has_world_read_node).and_return(true)
        expect(@hc.visibility).to eq(['world'])
      end

      it 'getter should return groups names if item is not world visible' do
        exp_groups = %w(foo bar)
        mock_nodes = exp_groups.map { |g| double('', text: g) }
        allow(@hc).to receive_message_chain(:rightsMetadata, :has_world_read_node).and_return(false)
        allow(@hc).to receive_message_chain(:rightsMetadata, :group_read_nodes).and_return(mock_nodes)
        expect(@hc.visibility).to eq(exp_groups)
      end

      it 'the setter should call the expected setters' do
        expect(@hc).to receive('visibility_option=').with('fixed')
        expect(@hc).to receive('visibility=').with('world')
        @hc.visibility_option_value = 'everyone'
      end
    end
  end

  describe 'dashboard stats and related methods' do
    before(:all) do
      @HC       = Hydrus::Collection
      @user_foo = 'user_foo'
    end

    describe 'dashboard_stats()' do
      it 'should return empty hash if there are no APOs involving the user' do
        expect(@HC).to receive(:apos_involving_user).and_return([])
        expect(@HC).not_to receive(:collections_of_apos)
        expect(@HC.dashboard_stats(@user_foo)).to eq({})
      end

      it 'should return empty hash if there are no Collections involving the user' do
        expect(@HC).to receive(:apos_involving_user).and_return([1, 2, 3])
        expect(@HC).to receive(:collections_of_apos).and_return([])
        expect(@HC).not_to receive(:item_counts_of_collections)
        expect(@HC.dashboard_stats(@user_foo)).to eq({})
      end

      it 'should return item_counts_of_collections() if there are relevant Collections' do
        exp = { foo: 1, bar: 2 }
        expect(@HC).to receive(:apos_involving_user).and_return([1, 2, 3])
        expect(@HC).to receive(:collections_of_apos).and_return([4, 5, 6])
        expect(@HC).to receive(:item_counts_of_collections).and_return(exp)
        expect(@HC.dashboard_stats(@user_foo)).to eq(exp)
      end
    end
    describe 'dashboard_hash' do
      it 'should send 1 solr query if there are 99 apos' do
        arr = *(1..99)
        expect(@HC).to receive(:apos_involving_user).and_return(arr)
        expect(@HC).to receive(:squery_collections_of_apos).exactly(1).times.and_return({})
        @HC.dashboard_hash(@user_foo)
      end
    end
    it 'can exercise initial_item_counts()' do
      h = @HC.initial_item_counts()
      expect(h).to be_instance_of(Hash)
      expect(h.values).to eq([0, 0, 0, 0])
    end

    it 'can exercise methods returning APO and Collection druids' do
      resp = double('mock_response')
      exp  = 12345
      allow(@HC).to receive(:issue_solr_query).and_return([resp, nil])
      expect(@HC).to receive(:get_druids_from_response).with(resp).exactly(3).and_return(exp)
      expect(@HC.apos_involving_user(@user_foo)).to eq(exp)
      expect(@HC.collections_of_apos([1, 2, 3, 4])).to eq(exp)
      expect(@HC.all_hydrus_collections).to eq(exp)
    end

    describe '#get_facet_counts_from_response' do
      let(:resp_hash) { { 'facet_pivot' => { a: exp } } }
      let(:resp) { instance_double(RSolr::HashWithResponse, fetch: resp_hash) }
      let(:exp) { 1234 }

      it 'returns the document identifiers' do
        expect(@HC.get_facet_counts_from_response(resp)).to eq(exp)
      end
    end

    it 'can exercise item_counts_with_labels()' do
      cs = {
        'draft' => 1,
        'awaiting_approval' => 2,
        'returned'          => 3,
        'published'         => 4,
      }
      allow(@hc).to receive(:item_counts).and_return(cs)
      exp = [
        [1, 'draft'],
        [2, 'waiting for approval'],
        [3, 'item returned'],
        [4, 'published'],
      ]
      expect(@hc.item_counts_with_labels).to eq(exp)
    end

    it 'item_counts_of_collections()' do
      exp = {
        'druid:xx000xx0001' => {
          'awaiting_approval' => 2,
          'returned'          => 3,
          'published'         => 4,
        },
        'druid:xx000xx0002' => {
          'draft'             => 14,
          'awaiting_approval' => 15,
          'returned'          => 16,
          'published'         => 17,
        },
        'druid:xx000xx0003' => {},
      }
      coll_pids = exp.keys
      fcs = [
        {
          'value' => "info:fedora/#{coll_pids[0]}",
          'pivot' => [
            { 'value' => 'draft',             'count' => 0 },
            { 'value' => 'awaiting_approval', 'count' => 2 },
            { 'value' => 'returned',          'count' => 3 },
            { 'value' => 'published',         'count' => 4 },
          ],
        },
        {
          'value' => "info:fedora/#{coll_pids[1]}",
          'pivot' => [
            { 'value' => 'draft',             'count' => 14 },
            { 'value' => 'awaiting_approval', 'count' => 15 },
            { 'value' => 'returned',          'count' => 16 },
            { 'value' => 'published',         'count' => 17 },
          ],
        },
      ]
      allow(@HC).to receive(:issue_solr_query).and_return([nil, nil])
      allow(@HC).to receive(:get_facet_counts_from_response).and_return(fcs)
      expect(@HC.item_counts_of_collections(coll_pids)).to eq(exp)
    end
  end
end
