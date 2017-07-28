require 'spec_helper'


describe Hydrus::GenericObject, type: :model do
  before(:each) do
    @cannot_do_regex = /\ACannot perform action/
    @go      = Hydrus::GenericObject.new
    @apo_pid = 'druid:oo000oo0002'
  end

  it 'apo() should return a new blank apo if the apo_pid is nil' do
    expect(@go.apo.class).to eq(Hydrus::AdminPolicyObject)
  end

  it 'dru() should return the druid without the prefix' do
    allow(@go).to receive(:pid).and_return('druid:oo000oo0003')
    expect(@go.dru).to eq('oo000oo0003')
  end

  describe 'apo' do
    it 'should be the admin policy object if it is defined' do
      apo = double(id: 'xyz')
      allow(@go).to receive(:admin_policy_object).and_return(apo)
      expect(@go.apo).to eq apo
    end

    it 'should default to a new APO object' do
      allow(@go).to receive(:admin_policy_object).and_raise ActiveFedora::ObjectNotFoundError.new
      expect(@go.apo).to be_a_kind_of Hydrus::AdminPolicyObject
    end
  end

  describe 'apo_pid' do
    it 'should return the pid of the APO' do
      allow(@go).to receive(:admin_policy_object).and_return(double(id: 'xyz'))
      expect(@go.apo_pid).to eq 'xyz'
    end
  end

  it 'can exercise discover_access()' do
    expect(@go.discover_access).to eq('')
  end

  it 'can exercise object_type()' do
    fake_imd = double('fake_imd', objectType: [123,456])
    expect(@go).to receive(:identityMetadata).and_return(fake_imd)
    expect(@go.object_type).to eq(123)
  end

  it 'can exercise url()' do
    allow(@go).to receive(:pid).and_return('__DO_NOT_USE__')
    expect(@go.purl_url).to eq('https://purl.stanford.edu/__DO_NOT_USE__')
  end

  it 'can exercise related_items()' do
    ris = @go.related_items
    expect(ris.size).to eq(1)
    ri = ris.first
    expect(ri.title).to eq('')
    expect(ri.url).to eq('')
  end

  describe 'registration' do
    it 'dor_registration_params() should return the expected hash' do
      # Non-APO: hash should include initiate_workflow.
      args = %w(whobar item somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      expect(drp).to be_instance_of Hash
      expect(drp[:admin_policy]).to eq(args.last)
      expect(drp).to include(:initiate_workflow)
      # APO: hash should not includes initiate_workflow.
      args = %w(whobar adminPolicy somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      expect(drp).to be_instance_of Hash
      expect(drp).to include(:initiate_workflow)
    end

    it 'should be able to exercise register_dor_object(), using stubbed call to Dor' do
      args = %w(whobar item somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      expectation = expect(Dor::RegistrationService).to receive(:register_object)
      expectation.with(hash_including(*drp.keys))
      Hydrus::GenericObject.register_dor_object(nil, nil, nil)
    end
  end

  describe 'license and terms of use' do
    describe 'license_groups(), license_commons(), and license_group_urls()' do
      it 'should get expected object types' do
        expect(Hydrus::GenericObject.license_groups).to be_a Array
        expect(Hydrus::GenericObject.license_commons).to be_a Hash
        expect(Hydrus::GenericObject.license_group_urls).to be_a Hash
      end

      it 'license_groups() labels should be keys in license_commons()' do
        hgo = Hydrus::GenericObject
        lgs = hgo.license_groups.map(&:first)
        lcs = hgo.license_commons.keys
        lcs.each { |lc| expect(lgs).to include(lc) }
      end
    end

    describe 'license() license=(), license_text(), and license_group_code()' do
      it 'setting license should also set license_text and license_group_code' do
        # Before.
        expect(@go.license).to eq('none')
        expect(@go.license_text).to eq('')
        expect(@go.license_group_code).to eq(nil)
        expect(@go.terms_of_use).to eq('')
        # Set a value for terms of use.
        tou = 'blah blah blah'
        @go.terms_of_use = tou
        # Check various license flavors.
        tests = [
          ['cc-by-nc', 'CC BY-NC Attribution-NonCommercial', 'creativeCommons'],
          ['odc-odbl', 'ODC-ODbl Open Database License',     'openDataCommons'],
          ['none',     '',                                   nil],
        ]
        tests.each do |lcode, txt, gcode|
          @go.license = lcode
          expect(@go.license).to eq(lcode)
          expect(@go.license_text).to eq(txt)
          expect(@go.license_group_code).to eq(gcode)
          # Terms of use should be unaffected.
          expect(@go.terms_of_use).to eq(tou)
          # License code in rightsMetadata XML should be correct.
          # In particular, the cc-by-nc code should be stored by by-nc.
          nd = @go.rightsMetadata.use.machine.nodeset.first
          expect(nd.text).to eq(lcode.sub(/\Acc-/, '')) if nd
        end
      end
    end

    it 'license_human() should return a human readable value for a license code' do
      hgo = Hydrus::GenericObject
      expect(hgo.license_human('cc-by')).to eq('CC BY Attribution')
      expect(hgo.license_human('cc-by-nc-sa')).to eq('CC BY-NC-SA Attribution-NonCommercial-ShareAlike')
      expect(hgo.license_human('odc-odbl')).to eq('ODC-ODbl Open Database License')
      expect(hgo.license_human('blah!!')).to match(/unknown license/i)
    end

    it 'terms_of_use: getter and setter' do
      exp = 'foobar'
      expect(@go.terms_of_use).to eq('')
      @go.terms_of_use = exp
      expect(@go.terms_of_use).to eq(exp)
    end
  end

  it 'set_item_type() should add correct tags' do
    tests = {
      collection: '<objectType>set</objectType>',
      dataset: '',
    }
    tests.each do |item_type, xml|
      exp  = "<identityMetadata>#{xml}</identityMetadata>"
      obj  = Hydrus::GenericObject.new
      idmd = Dor::IdentityMetadataDS.new(nil, nil)
      allow(obj).to receive(:identityMetadata).and_return(idmd)
      obj.set_item_type(item_type)
      expect(idmd.ng_xml).to be_equivalent_to exp
    end
  end
  context 'set_item_type' do
    before :each do
      @obj = Hydrus::GenericObject.new
      @descMD = Dor::DescMetadataDS.new(nil, nil)
    end
    def type_of_resource
      @obj.descMetadata.ng_xml.search('//mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').first.text
    end
    def genre
      @obj.descMetadata.ng_xml.search('//mods:genre', 'mods' => 'http://www.loc.gov/mods/v3').first.text
    end
  it 'set_item_type() should set the correct desc metadata fields for a dataset' do
      @obj.set_item_type('dataset')
      expect(type_of_resource).to eq('software, multimedia')
      expect(genre).to eq('dataset')
  end
  it 'set_item_type() should set the correct desc metadata fields for a thesis' do
      @obj.set_item_type('thesis')
      expect(type_of_resource).to eq('text')
      expect(genre).to eq('thesis')
      expect(@obj.descMetadata.ng_xml.search('//mods:genre', 'mods' => 'http://www.loc.gov/mods/v3').first['authority']).to eq('marcgt')
  end
  it 'set_item_type() should set the correct desc metadata fields for a article' do
      @obj.set_item_type('article')
      expect(type_of_resource).to eq('text')
      expect(genre).to eq('article')
      expect(@obj.descMetadata.ng_xml.search('//mods:genre', 'mods' => 'http://www.loc.gov/mods/v3').first['authority']).to eq('marcgt')
  end

  it 'set_item_type() should set the correct desc metadata fields for a class project' do
      @obj.set_item_type('class project')
      expect(type_of_resource).to eq('text')
      expect(genre).to eq('student project report')
  end
  it 'set_item_type() should set the correct desc metadata fields for a computer game' do
      @obj.set_item_type('computer game')
      expect(type_of_resource).to eq('software, multimedia')
      expect(genre).to eq('game')
  end
  it 'set_item_type() should set the correct desc metadata fields for a audio - music' do
      @obj.set_item_type('audio - music')
      expect(type_of_resource).to eq('sound recording-musical')
      expect(genre).to eq('sound')
  end
  it 'set_item_type() should set the correct desc metadata fields for a audio - spoken' do
      @obj.set_item_type('audio - spoken')
      expect(type_of_resource).to eq('sound recording-nonmusical')
      expect(genre).to eq('sound')
  end
  it 'set_item_type() should set the correct desc metadata fields for a conference paper / presentation' do
      @obj.set_item_type('conference paper / presentation')
      expect(type_of_resource).to eq('text')
      expect(genre).to eq('conference publication')
  end
  it 'set_item_type() should set the correct desc metadata fields for a technical report' do
      @obj.set_item_type('technical report')
      expect(type_of_resource).to eq('text')
      expect(genre).to eq('technical report')
  end
  it 'set_item_type() should set the correct desc metadata fields for a video' do
      @obj.set_item_type('video')
      expect(type_of_resource).to eq('moving image')
      expect(genre).to eq('motion picture')
  end
  it 'set_item_type() should set the correct desc metadata fields for a video' do
      @obj.set_item_type('video')
      expect(type_of_resource).to eq('moving image')
      expect(genre).to eq('motion picture')
  end
  it 'should set the correct desc metadata fields for an image' do
      @obj.set_item_type('image')
      expect(type_of_resource).to eq('still image')
  end
  it 'set_item_type() should set the correct desc metadata fields for archival mixed material ' do
      @obj.set_item_type('archival mixed material')
      expect(type_of_resource).to eq('mixed material')
      expect(@obj.descMetadata.ng_xml.search('//mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').first['manuscript']).to eq('yes')
  end
  it 'should set the correct desc metadata fields for software' do
      @obj.set_item_type('software')
      expect(type_of_resource).to eq('software, multimedia')
  end
  it 'should set the correct desc metadata fields for a textbook' do
      @obj.set_item_type('textbook')
      expect(type_of_resource).to eq('text')
      expect(genre).to eq('instruction')
  end

  it 'set_item_type() should set the correct desc metadata fields for a collection' do
      @obj.set_item_type(:collection)
      expect(type_of_resource).to eq('')
      expect(@obj.descMetadata.ng_xml.search('//mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').first['collection']).to eq('yes')
  end
end

  describe 'workflow stuff' do
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
      allow(@go).to receive(:workflows).and_return(@workflow)
    end

    it 'get_workflow_node() should return a node with correct id attribute' do
      node = @go.workflows.get_workflow_node
      expect(node).to be_instance_of Nokogiri::XML::Element
      expect(node['id']).to eq(Dor::Config.hydrus.app_workflow.to_s)
    end

    it 'get_workflow_step() should return a node with correct name attribute' do
      node = @go.workflows.get_workflow_step('approve')
      expect(node).to be_instance_of Nokogiri::XML::Element
      expect(node['name']).to eq('approve')
    end

    it 'get_workflow_status() should return the current status of a step' do
      expect(@go.workflows.get_workflow_status('start-deposit')).to eq('completed')
      expect(@go.workflows.get_workflow_status('submit')).to        eq('waiting')
      expect(@go.workflows.get_workflow_status('blort')).to         eq(nil)
    end

    it 'workflow_step_is_done() should return correct value' do
      expect(@go.workflows.workflow_step_is_done('start-deposit')).to eq(true)
      expect(@go.workflows.workflow_step_is_done('submit')).to        eq(false)
    end

    it 'is_published() should return true if object status is any flavor of publish' do
      tests = {
        'published'         => true,
        'published_open'    => true,
        'published_closed'  => true,
        'draft'             => false,
        'awaiting_approval' => false,
      }
      tests.each do |status, exp|
        allow(@go).to receive(:object_status).and_return(status)
        expect(@go.is_published).to eq(exp)
      end
    end
  end

  describe 'validations' do
    before(:each) do
      @exp = [:pid, :contact]
      @go.instance_variable_set('@should_validate', true)
    end

    it 'blank slate object (should_validate=false) should include only the :pid error' do
      allow(@go).to receive(:should_validate).and_return(false)
      expect(@go.valid?).to eq(false)
      expect(@go.errors.messages.keys).to eq([@exp.first])
    end

    it 'blank slate object should include all validation errors' do
      expect(@go.valid?).to eq(false)
      expect(@go.errors.messages).to include(*@exp)
    end

    it 'fully populated object should not be valid if contact email is invalid' do
      dru = 'druid:ll000ll0001'
      @exp.each { |e| allow(@go).to receive(e).and_return(dru)}
      expect(@go.valid?).to eq(false)
    end

    it 'fully populated object should be valid if contact email is valid' do
      dru = 'druid:ll000ll0001'
      @exp.each { |e| allow(@go).to receive(e).and_return(dru) unless e == :contact}
      allow(@go).to receive(:contact).and_return('test@test.com')
      expect(@go.valid?).to eq(true)
    end
  end

  describe 'events stuff' do
    before(:each) do
      xml = <<-EOF
        <events>
          <event type="hydrus" who="sunetid:foo" when="2012-08-15T10:11:31-07:00">blah</event>
          <event type="hydrus" who="sunetid:foo" when="2012-08-15T10:12:31-07:00">blort</event>
        </events>
      EOF
      @events = Dor::EventsDS.from_xml(noko_doc(xml))
      @go = Hydrus::GenericObject.new
      allow(@go).to receive(:events).and_return(@events)
    end

    it 'get_workflow_node() should return a node with correct id attribute' do
      es = @go.get_hydrus_events
      expect(es.size).to eq(2)
      e = es.first
      expect(e).to be_instance_of Hydrus::Event
      expect(e.type).to eq('hydrus')
      expect(e.who).to  eq('sunetid:foo')
      expect(e.when.year).to  eq(2012)
      expect(e.when.month).to eq(8)
      expect(e.when.day).to   eq(15)
      expect(e.text).to eq('blah')
    end
  end

  it 'hydrus_class_to_s() should work as expected' do
    tests = {
      Hydrus::Item       => 'Item',
      Hydrus::Collection => 'Collection',
      String             => 'String',
      Dor::EventsDS      => 'Dor::EventsDS',
    }
    tests.each do |cls, exp|
      allow(@go).to receive(:class).and_return(cls)
      expect(@go.hydrus_class_to_s).to eq(exp)
    end
  end

  it 'publish_metadata() should do nothing if app is not configured to start common assembly' do
    allow(@go).to receive(:should_start_assembly_wf).and_return(false)
    expect(@go).not_to receive(:is_assemblable)
    @go.publish_metadata
  end

  describe 'current_user' do
    it '@current_user should be initialized in a lazy fashion' do
      expect(@go.instance_variable_get('@current_user')).to eq(nil)
      expect(@go.current_user).to eq('')
      expect(@go.instance_variable_get('@current_user')).to eq('')
    end

    it 'can exercise current_user=()' do
      expect(@go.instance_variable_get('@current_user')).to eq(nil)
      @go.current_user = 123
      expect(@go.instance_variable_get('@current_user')).to eq(123)
    end
  end

  it "old_self() should call find() with the object's pid" do
    pid = @go.pid
    r = 'blah blah!!'
    expect(Hydrus::GenericObject).to receive(:find).with(pid).and_return(r)
    expect(@go.old_self).to eq(r)
  end

  it 'editing_event_message() should return expected string' do
    fs  = [:foo, :bar, :quux]
    exp = 'GenericObject modified: foo, bar, quux'
    expect(@go.editing_event_message(fs)).to eq(exp)
  end

  it 'changed_fields() should return ...' do
    tf = {
      a: [:aa],
      bb: [:ba, :bb],
      ccc: [:ca, :cb, :cc],
      ddd: [:da, :db],
    }
    allow(@go).to receive(:tracked_fields).and_return(tf)
    old = double('old_self')
    exp_diff = [:a, :ccc]
    tf.each do |k,vs|
      vs.each do |v|
        allow(old).to receive(v).and_return(v.to_s)
        allow(@go).to receive(v).and_return(exp_diff.include?(k) ? 'new_val' : v.to_s)
      end
    end
    allow(@go).to receive(:old_self).and_return(old)
    expect(@go.changed_fields).to eq(exp_diff)
  end

  it 'GenericObject does not implement tracked_fields()' do
    expect{ @go.tracked_fields }.to raise_error(NoMethodError)
  end

  describe 'object returned email' do
    it 'should provide a method to send object returned emails' do
      allow(@go).to receive(:recipients_for_object_returned_email).and_return('jdoe')
      allow(@go).to receive_messages(object_type: 'item')
      mail = @go.send_object_returned_email_notification(item_url: '/fake/it')
      expect(mail.to).to eq(['jdoe@stanford.edu'])
      expect(mail.subject).to match(/Item returned in the Stanford Digital Repository/)
    end
    it 'should return nil when no recipients are sent in' do
      allow(@go).to receive(:recipients_for_object_returned_email).and_return('')
      expect(@go.send_object_returned_email_notification).to be_nil
    end
  end

  describe 'log_editing_events()' do
    it 'should do nothing if there are no changed fields' do
      allow(@go).to receive(:changed_fields).and_return([])
      expect(@go).not_to receive(:events)
      @go.log_editing_events
    end

    it 'should add an editing event if there are changed fields' do
      allow(@go).to receive(:changed_fields).and_return([:aa, :bb])
      expect(@go.get_hydrus_events.size).to eq(0)
      @go.log_editing_events
      es = @go.get_hydrus_events
      expect(es.size).to eq(1)
      expect(es.first.text).to eq('GenericObject modified: aa, bb')
    end
  end

  describe 'save()' do
    context 'on an existing object' do
      before do
        allow(@go).to receive(:new_record?).and_return(false)
      end
      it 'invokes log_editing_events()' do
        expect(@go).to receive(:log_editing_events).once
        @go.save(no_super: true)
      end

      context 'when no_edit_logging is false' do
        it 'should not invoke log_editing_events() if no_edit_logging is true' do
          expect(@go).not_to receive(:log_editing_events)
          @go.save(no_edit_logging: true, no_super: true)
        end
      end
    end
  end

  it 'is_item? and is_collection? should work' do
    hi = Hydrus::Item.new
    hc = Hydrus::Collection.new
    go = @go
    expect(hi.is_item?).to eq(true)
    expect(hc.is_item?).to eq(false)
    expect(go.is_item?).to eq(false)
    expect(hi.is_collection?).to eq(false)
    expect(hc.is_collection?).to eq(true)
    expect(go.is_collection?).to eq(false)
  end

  it 'can exercise status_label()' do
    tests = {
      'draft'          => 'draft',
      'published_open' => 'published',
      'published'      => 'published',
      'returned'       => 'item returned',
    }
    tests.each do |status, exp|
      allow(@go).to receive(:object_status).and_return(status)
      expect(@go.status_label).to eq(exp)
    end
  end

  it 'can exercise Hydrus::GenericObject.status_labels()' do
    tests = [:collection, :item]
    tests.each do |k|
      expect(Hydrus::GenericObject.status_labels(k)).to be_instance_of Hash
    end
  end

  it 'cannot_do() should raise an exception' do
    expect { @go.cannot_do(:foo) }.to raise_error(/^Cannot perform action.+=foo/)
  end

  describe 'XML beautification' do
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

    it 'beautified_xml()' do
      expect(@go.beautified_xml(@orig_xml)).to eq(@exp)
    end

    it 'beautify_datastream()' do
      allow(@go.descMetadata).to receive(:content).and_return @orig_xml
      expect(@go.descMetadata).to receive(:content=).with(@exp)
      @go.beautify_datastream(:descMetadata)
    end
  end

  it 'related_item_url=() and related_item_title=()' do
    # Initial state.
    expect(@go.related_item_title).to eq([''])
    expect(@go.related_item_url).to eq([''])
    # Assign a single value.
    @go.related_item_title = 'Z'
    @go.related_item_url = 'foo'
    expect(@go.related_item_title).to eq(['Z'])
    expect(@go.related_item_url).to eq(['http://foo'])
    # Add two mode nodes.
    @go.descMetadata.insert_related_item
    @go.descMetadata.insert_related_item
    # Set using hashes.
    @go.related_item_title = {'0' => 'A', '1' => 'B', '2' => 'C'}
    @go.related_item_url   = {'0' => 'boo', '1' => 'bar', '2' => 'ftp://quux'}
    expect(@go.related_item_title).to eq(%w(A B C))
    expect(@go.related_item_url).to eq(['http://boo', 'http://bar', 'ftp://quux'])
    # Also confirm that each title and URL is put in its own relatedItem node.
    # We had bugs causing them to be put all in the first node.
    ri_nodes = @go.descMetadata.find_by_terms(:relatedItem)
    expect(ri_nodes.size).to eq(3)
    ri_nodes.each do |nd|
      nd = Nokogiri::XML(nd.to_s, &:noblanks)  # Generic XML w/o namespaces.
      expect(nd.xpath('//title').size).to eq(1)
      expect(nd.xpath('//url').size).to eq(1)
    end
  end

  it 'with_protocol()' do
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
      expect(@go.with_protocol(uri)).to eq(exp)
    end
  end
end
