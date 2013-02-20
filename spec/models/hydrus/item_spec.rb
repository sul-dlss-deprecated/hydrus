require 'spec_helper'

describe Hydrus::Item do

  before(:each) do
    @cannot_do_regex = /\ACannot perform action/
    @hi = Hydrus::Item.new
    @hc = Hydrus::Collection.new
    @hi.stub(:collection).and_return(@hc)
    @workflow_xml = <<-END
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workflows objectId="druid:oo000oo0001">
        <workflow repository="dor" objectId="druid:oo000oo0001" id="hydrusAssemblyWF">
          <process version="1" lifecycle="registered" elapsed="0.0" attempts="0" datetime="1234" status="completed" name="start-deposit"/>
          <process version="1" elapsed="0.0" attempts="0" datetime="9999" status="completed" name="submit"/>
          <process version="1" elapsed="0.0" attempts="0" datetime="1234" name="approve"/>
          <process version="1" elapsed="0.0" attempts="0" datetime="1234" name="start-assembly"/>
        </workflow>
      </workflows>
    END
    @workflow_xml = noko_doc(@workflow_xml)
  end

  it "can exercise a stubbed version of create()" do
    # More substantive testing is done at integration level.
    Hydrus::Authorizable.stub(:can_create_items_in).and_return(true)
    # Stub out the Collection find() method.
    hc = Hydrus::Collection.new
    hc.stub(:visibility_option_value).and_return('varies')
    hc.stub(:is_open).and_return(true)
    Hydrus::Collection.stub(:find).and_return(hc)
    # Set up an Item for use when stubbing register_dor_object().
    druid = 'druid:BLAH'
    stubs = [
      :remove_relationship,
      :assert_content_model,
      :add_to_collection,
      :augment_identity_metadata,
    ]
    stubs.each { |s| @hi.should_receive(s) }
    @hi.should_receive(:save).with(:no_edit_logging => true, :no_beautify => true)
    @hi.stub(:pid).and_return(druid)
    @hi.stub(:adapt_to).and_return(@hi)
    @hi.stub(:collection).and_return(hc)
    Hydrus::GenericObject.stub(:register_dor_object).and_return(@hi)
    # Call create().
    obj = Hydrus::Item.create(hc.pid, mock_user)
    obj.pid.should == druid
    obj.get_hydrus_events.size.should == 1
    obj.terms_of_use.should =~ /user agrees/i
    obj.version_started_time.should =~ /\A\d{4}/
    obj.version_tag.should == 'v1.0.0'
  end

  it "can exercise a stubbed version of create when terms have already been accepted on another item" do
    # More substantive testing is done at integration level.
    druid = 'druid:BLAH'
    stubs = [
      :remove_relationship,
      :assert_content_model,
      :add_to_collection,
      :augment_identity_metadata,
    ]
    stubs.each { |s| @hi.should_receive(s) }
    @hi.should_receive(:save).with(:no_edit_logging => true, :no_beautify => true)
    @hi.stub(:pid).and_return(druid)
    @hi.stub(:adapt_to).and_return(@hi)
    @hi.stub(:requires_terms_acceptance).and_return(false)
    hc = Hydrus::Collection.new
    hc.stub(:visibility_option_value).and_return('varies')
    hc.stub(:is_open).and_return(true)
    Hydrus::Collection.stub(:find).and_return(hc)
    Hydrus::GenericObject.stub(:register_dor_object).and_return(@hi)
    @hi.stub(:collection).and_return(hc)
    Hydrus::Authorizable.stub(:can_create_items_in).and_return(true)
    new_item=Hydrus::Item.create(hc.pid, mock_user)
    new_item.pid.should == druid
    new_item.terms_of_deposit_accepted?.should be true
  end

  it "should be able to add and remove an item from a collection" do
    collection_pid = 'druid:xx99xx9999'
    exp_uri        = "info:fedora/#{collection_pid}"

    # Initially, the item is not a member of a collection.
    @hi.relationships(:is_member_of).should == []
    @hi.relationships(:is_member_of_collection).should == []

    # Add it to a collection, and confirm the relationships.
    @hi.add_to_collection(collection_pid)
    @hi.relationships(:is_member_of).should == [exp_uri]
    @hi.relationships(:is_member_of_collection).should == [exp_uri]

    # Remove it from the collection, and confirm.
    @hi.remove_from_collection(collection_pid)
    @hi.relationships(:is_member_of).should == []
    @hi.relationships(:is_member_of_collection).should == []
  end

  describe "#files" do
    subject { Hydrus::Item.new }

    it "should retrieve ObjectFiles from the database" do
      m = mock()
      Hydrus::ObjectFile.should_receive(:find_all_by_pid).with(subject.pid, hash_including(:order => 'weight')).and_return(m)
      subject.files.should == m
    end
  end

  describe "#contributors" do

    before(:each) do
      @rattr = 'authority="marcrelator" type="text"'
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <name type="personal">
            <namePart>Angus</namePart>
            <role><roleTerm #{@rattr}>Guitar</roleTerm></role>
          </name>
          <name type="personal">
            <namePart>Cliff</namePart>
            <role><roleTerm #{@rattr}>Bass</roleTerm></role>
          </name>
          <name type="corporate">
            <namePart>EMI</namePart>
            <role><roleTerm #{@rattr}>Record Company</roleTerm></role>
          </name>
        </mods>
      eos
      @hi.stub(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
    end

    it "contributors()" do
      @hi.contributors.length.should == 3
      @hi.contributors.all? { |c| c.should be_instance_of(Hydrus::Contributor) }
    end

    it "insert_contributor()" do
      extra_xml = <<-eos
        <name type="corporate">
          <namePart>FooBar</namePart>
          <role><roleTerm #{@rattr}>Sponsor</roleTerm></role>
        </name>
        <name type="personal">
          <namePart></namePart>
          <role><roleTerm #{@rattr}>Author</roleTerm></role>
        </name>
      eos
      @hi.insert_contributor('FooBar', 'corporate_sponsor')
      @hi.insert_contributor
      new_xml = @xml.sub(/<\/mods>/, extra_xml + '</mods>')
      @hi.descMetadata.ng_xml.should be_equivalent_to(new_xml)
    end

    it "contributors=()" do
      exp = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <name type="corporate">
            <namePart>AAA</namePart>
            <role><roleTerm #{@rattr}>Author</roleTerm></role>
          </name>
          <name type="personal">
            <namePart>BBB</namePart>
            <role><roleTerm #{@rattr}>Author</roleTerm></role>
          </name>
        </mods>
      eos
      @hi.contributors = {
        "0" => {"name"=>"AAA", "role"=>"corporate_author"},
        "1" => {"name"=>"BBB", "role"=>"personal_author"},
      }
      @hi.descMetadata.ng_xml.should be_equivalent_to(exp)
    end

  end

  describe "#add_to_collection" do
    subject { Hydrus::Item.new }

    it "should add 'set' and 'collection' relations" do
      subject.should_receive(:add_relationship_by_name).with('set', 'info:fedora/collection_pid')
      subject.should_receive(:add_relationship_by_name).with('collection', 'info:fedora/collection_pid')
      subject.add_to_collection('collection_pid')
    end
  end

  describe "#remove_from_collection" do
    subject { Hydrus::Item.new }

    it "should remove 'set' and 'collection' relations" do
      subject.should_receive(:remove_relationship_by_name).with('set', 'info:fedora/collection_pid')
      subject.should_receive(:remove_relationship_by_name).with('collection', 'info:fedora/collection_pid')
      subject.remove_from_collection('collection_pid')
    end
  end

  describe "roleMetadata in the item", :integration=>true do
    subject { Hydrus::Item.find('druid:oo000oo0001') }
    it "should have a roleMetadata datastream" do
      subject.roleMetadata.should be_an_instance_of(Hydrus::RoleMetadataDS)
      subject.item_depositor_id.should == 'archivist1'
      subject.item_depositor_name.should == 'Archivist, One'
    end
  end

  describe "keywords" do

    before(:each) do
      @mods_start = '<mods xmlns="http://www.loc.gov/mods/v3">'
      xml = <<-EOF
        #{@mods_start}
          <subject><topic>divorce</topic></subject>
          <subject><topic>marriage</topic></subject>
        </mods>
      EOF
      @dsdoc = Hydrus::DescMetadataDS.from_xml(xml)
      @hi.stub(:descMetadata).and_return(@dsdoc)
    end

    it "keywords() should return expected values" do
      @hi.keywords.should == %w(divorce marriage)
    end

    it "keywords= should rewrite all <subject> nodes" do
      @hi.keywords = ' foo , bar , quux  '
      @dsdoc.ng_xml.should be_equivalent_to <<-EOF
        #{@mods_start}
          <subject><topic>foo</topic></subject>
          <subject><topic>bar</topic></subject>
          <subject><topic>quux</topic></subject>
        </mods>
      EOF
    end

    it "keywords= should not modify descMD if the keywords are same as existing" do
      kws = %w(foo bar)
      @hi.stub(:keywords).and_return(kws)
      @hi.should_not_receive(:descMetadata)
      @hi.keywords = kws.join(',')
    end

  end

  describe "visibility()" do

    it "should return [] for initial visibility" do
      tests = [true, false]
      tests.each do |is_emb|
        @hi.stub(:is_embargoed).and_return(is_emb)
        @hi.visibility.should == []
      end
    end

    it "should return ['world'] if item is world visible" do
      tests = {
        true  => :embargoMetadata,
        false => :rightsMetadata,
      }
      tests.each do |is_emb, ds|
        @hi.stub(:is_embargoed).and_return(is_emb)
        @hi.stub_chain(ds, :has_world_read_node).and_return(true)
        @hi.visibility.should == ['world']
      end
    end

    it "should return array of groups if item is visible to specific groups" do
      tests = {
        true  => :embargoMetadata,
        false => :rightsMetadata,
      }
      exp_groups = %w(foo bar)  # Typically, just ['stanford']
      mock_nodes = exp_groups.map { |g| double('', :text => g) }
      tests.each do |is_emb, ds|
        @hi.stub(:is_embargoed).and_return(is_emb)
        @hi.stub_chain(ds, :has_world_read_node).and_return(false)
        @hi.stub_chain(ds, :group_read_nodes).and_return(mock_nodes)
        @hi.visibility.should == exp_groups
      end
    end

  end

  describe "embarg_visib=()" do

    before(:each) do
      @edate = '2012-02-28T08:00:00Z'
      # XML snippets for various <access> nodes.
      ed       = "<embargoReleaseDate>#{@edate}</embargoReleaseDate>"
      mw       = '<machine><world/></machine>'
      ms       = '<machine><group>stanford</group></machine>'
      me       = "<machine>#{ed}</machine>"
      rd_world = %Q[<access type="read">#{mw}</access>]
      rd_stanf = %Q[<access type="read">#{ms}</access>]
      rd_emb   = %Q[<access type="read">#{me}</access>]
      di_world = %Q[<access type="discover">#{mw}</access>]
      # XML snippets for embargoMetadata.
      em_date  = %Q[<releaseDate>#{@edate}</releaseDate>]
      em_start = %Q[<embargoMetadata><status>embargoed</status>#{em_date}]
      em_end   = %Q[</embargoMetadata>]
      em_world = %Q[<releaseAccess>#{di_world}#{rd_world}</releaseAccess>]
      em_stanf = %Q[<releaseAccess>#{di_world}#{rd_stanf}</releaseAccess>]
      # XML snippets for rightsMetadata.
      rm_start = %Q[<rightsMetadata>]
      rm_end   = '<access type="edit"><machine/></access>' +
                 '<use><human type="useAndReproduction"/></use>' +
                 '</rightsMetadata>'
      # Assemble expected Nokogiri XML for embargoMetadata and rightsMetadata.
      @xml = {
        :em_world   => noko_doc([em_start, em_world, em_end].join),
        :em_stanf   => noko_doc([em_start, em_stanf, em_end].join),
        :rm_emb     => noko_doc([rm_start, di_world, rd_emb,   rm_end].join),
        :rm_world   => noko_doc([rm_start, di_world, rd_world, rm_end].join),
        :rm_stanf   => noko_doc([rm_start, di_world, rd_stanf, rm_end].join),
      }
    end

    it "can exercise all combinations of is_embargoed and visibility to get expected XML" do
      # All permutations of embargoed = yes|no and visibility = world|stanford,
      # along with the expected rightsMetadata and embargoMetadata XML keys.
      tests = [
        [true,  'world',    :rm_emb,   :em_world],
        [true,  'stanford', :rm_emb,   :em_stanf],
        [false, 'world',    :rm_world, nil],
        [false, 'stanford', :rm_stanf, nil],
      ]
      dt = HyTime.date_display(@edate)
      tests.each do |emb, vis, exp_rm, exp_em|
        h = {
          'embargoed'  => emb ? 'yes' : 'no',
          'date'       => emb ? dt    : '',
          'visibility' => vis,
        }
        @hi = Hydrus::Item.new
        @hi.embargoMetadata.should_receive(:delete) unless emb
        @hi.embarg_visib = h
        @hi.rightsMetadata.ng_xml.should  be_equivalent_to(@xml[exp_rm])
        @hi.embargoMetadata.ng_xml.should be_equivalent_to(@xml[exp_em]) if emb
      end
    end

  end

  describe "embargo" do

    it "is_embargoed should return true if the Item has a non-blank embargo date" do
      tests = {
        ''                     => false,
        nil                    => false,
        '2012-08-30T08:00:00Z' => true,
      }
      tests.each do |dt, exp|
        @hi.stub(:embargo_date).and_return(dt)
        @hi.is_embargoed.should == exp
      end
    end

    describe "embargo_date() and embargo_date=()" do

      it "getter should return value from embargoMetadata" do
        exp = 'foo release date'
        @hi.stub_chain(:embargoMetadata, :release_date).and_return(exp)
        @hi.embargo_date.should == exp
      end

      describe "setter: with valid date" do

        it "store date in UTC in both embargoMD and rightsMD" do
          rd = '2012-08-30'
          rd_dt = HyTime.datetime("#{rd}T08:00:00Z")
          @hi.embargo_date = rd
          @hi.embargo_date.should == rd_dt
          @hi.rmd_embargo_release_date.should == rd_dt
          @hi.embargoMetadata.status.should == 'embargoed'
          @hi.instance_variable_get('@embargo_date_was_malformed').should == nil
        end

      end

      describe "setter: with invalid date" do

        it "blank or nil: delete embargoMetadata; do not set instance var" do
          @hi.embargoMetadata.should_receive(:delete)
          dt = rand() < 0.5 ? '' : nil
          @hi.embargo_date = dt
          @hi.rightsMetadata.ng_xml.at_xpath("//embargoReleaseDate").should == nil
          @hi.instance_variable_get('@embargo_date_was_malformed').should == nil
        end

        it "malformed: do not delete embargoMetadata; set instance var" do
          @hi.embargoMetadata.should_not_receive(:delete)
          @hi.embargo_date = 'blah'
          @hi.rightsMetadata.ng_xml.at_xpath("//embargoReleaseDate").should == nil
          @hi.instance_variable_get('@embargo_date_was_malformed').should == true
        end

      end

    end

    describe "beginning_of_embargo_range()" do

      it "initial_publish_time missing: should return now_datetime()" do
        exp = 'foo bar'
        HyTime.stub(:now_datetime).and_return(exp)
        @hi.stub(:initial_publish_time).and_return(nil)
        @hi.beginning_of_embargo_range.should == exp
      end

      it "initial_publish_time present: should return it" do
        exp = 'foo bar blah'
        @hi.stub(:initial_publish_time).and_return(exp)
        @hi.beginning_of_embargo_range.should == exp
      end

    end

    describe "end_of_embargo_range()" do

      it "should get the end date range properly based on the collection's APO" do
        t = 'T00:00:00Z'
        @hi.stub(:beginning_of_embargo_range).and_return("2012-08-01#{t}")
        tests = {
          '6 months' => "2013-02-01#{t}",
          '1 year'   => "2013-08-01#{t}",
          '5 years'  => "2017-08-01#{t}",
        }
        tests.each do |emb, exp|
          @hi.stub_chain(:collection, :embargo_terms).and_return(emb)
          @hi.end_of_embargo_range.should == exp
        end
      end

    end

    describe "embargo_can_be_changed()" do

      # def embargo_can_be_changed
      #   # Collection must allow it.
      #   return false unless collection.embargo_option == 'varies'
      #   # Behavior varies by version.
      #   if is_initial_version
      #     return true
      #   else
      #     # In subsequent versions, Item must
      #     #   - have an existing embargo
      #     #   - that has a max embargo date some time in the future
      #     return false unless is_embargoed
      #     return HyTime.now < end_of_embargo_range.to_datetime
      #   end
      # end

      it "Collection does not allow embargo variability: should return false" do
        @hi.should_not_receive(:is_initial_version)
        %w(none fixed).each do |opt|
          @hc.stub(:embargo_option).and_return(opt)
          @hi.embargo_can_be_changed.should == false
        end
      end

      describe "Collection allows embargo variability" do

        before(:each) do
          @hc.stub(:embargo_option).and_return('varies')
        end

        it "initial version: always true" do
          @hi.stub(:is_initial_version).and_return(true)
          @hi.should_not_receive(:is_embargoed)
          @hi.embargo_can_be_changed.should == true
        end

        it "subsequent versions: not embargoed: always false" do
          @hi.stub(:is_initial_version).and_return(false)
          @hi.stub(:is_embargoed).and_return(false)
          @hi.should_not_receive(:end_of_embargo_range)
          @hi.embargo_can_be_changed.should == false
        end

        it "subsequent versions: embargoed: true if end_of_embargo_range is in future" do
          @hi.stub(:is_initial_version).and_return(false)
          @hi.stub(:is_embargoed).and_return(true)
          tpast = HyTime.datetime(HyTime.now - 2.day)
          tfut  = HyTime.datetime(HyTime.now + 2.day)
          @hi.stub(:end_of_embargo_range).and_return(tpast)
          @hi.embargo_can_be_changed.should == false
          @hi.stub(:end_of_embargo_range).and_return(tfut)
          @hi.embargo_can_be_changed.should == true
        end

      end

    end

  end

  describe "strip_whitespace_from_fields()" do

    before(:each) do
      xml = <<-eos
       <mods xmlns="http://www.loc.gov/mods/v3">
          <abstract>  Blah blah  </abstract>
          <titleInfo><title>  Learn VB in 21 Days  </title></titleInfo>
       </mods>
      eos
      dmd = Hydrus::DescMetadataDS.from_xml(xml)
      @hi = Hydrus::Item.new
      @hi.stub(:descMetadata).and_return(dmd)
    end

    it "should be able to call method on a Hydrus::Item to remove whitespace" do
      a = @hi.abstract
      t = @hi.title
      @hi.strip_whitespace_from_fields([:abstract, :title])
      @hi.abstract.should == a.strip
      @hi.title.should == t.strip
    end

  end

  describe "validations" do

    before(:each) do
      @exp = [
        :pid,
        :collection,
        :files,
        :title,
        :abstract,
        :contact,
        :terms_of_deposit,
        :release_settings,
      ]
      @hi.instance_variable_set('@should_validate', true)
    end

    it "blank slate Item (should_validate=false) should include only two errors" do
      @hi.stub(:should_validate).and_return(false)
      @hi.valid?.should == false
      @hi.errors.messages.keys.should include(*@exp[0..1])
    end

    it "blank slate Item (should_validate=true) should include all errors" do
      @hi.valid?.should == false
      @hi.errors.messages.keys.should include(*@exp)
    end

    describe "embargo_date_in_range()" do

      it "should not perform validation unless preconditions are met" do
        @hi.should_not_receive(:beginning_of_embargo_range)
        @hi.stub(:is_embargoed).and_return(false)
        @hi.embargo_date_in_range
      end

      it "should add a validation error when embargo_date falls outside the embargo range" do
        # Set up beginning/end of embargo range.
        b   = '2012-02-01T08:00:00Z'
        e   = '2012-03-01T08:00:00Z'
        bdt = HyTime.datetime(b)
        edt = HyTime.datetime(e)
        @hi.stub(:beginning_of_embargo_range).and_return(bdt)
        @hi.stub(:end_of_embargo_range).and_return(edt)
        exp_msg = "must be in the range #{b[0..9]} through #{e[0..9]}"
        # Some embargo dates to validate.
        dts = {
          '2012-01-31T08:00:00Z' => false,
          '2012-02-01T08:00:00Z' => true,
          '2012-02-25T08:00:00Z' => true,
          '2012-03-01T08:00:00Z' => true,
          '2012-03-02T08:00:00Z' => false,
        }
        # Validate those dates.
        @hi.stub(:is_embargoed).and_return(true)
        k = :embargo_date
        dts.each do |dt, is_ok|
          @hi.errors.should_not have_key(k)
          @hi.stub(k).and_return(HyTime.datetime(dt))
          @hi.embargo_date_in_range
          if is_ok
            @hi.errors.should_not have_key(k)
          else
            @hi.errors.should have_key(k)
            @hi.errors.messages[k].first.should == exp_msg
          end
          @hi.errors.clear
        end
      end

    end

    it "fully populated Item should be valid" do
      dru = 'druid:ll000ll0001'
      @hi.stub(:enforce_collection_is_open).and_return(true)
      @hi.stub(:accepted_terms_of_deposit).and_return(true)
      @hi.stub(:reviewed_release_settings).and_return(true)
      @exp.each { |e| @hi.stub(e).and_return(dru) unless e==:contact }
      @hi.stub(:contact).and_return('test@test.com') # we need a valid email address
      @hi.stub(:keywords).and_return(%w(aaa bbb))
      @hi.stub_chain([:collection, :embargo_option]).and_return("varies")
      @hi.valid?.should == true
    end

    it "enforce_collection_is_open() should return true only if the Item is in an open Collection" do
      n  = 0
      [true, false, nil].each do |stub_val|
        c    = double('collection', :is_open => stub_val)
        exp  = not(not(stub_val))
        n   += 1 unless exp
        @hi.stub(:collection).and_return(c)
        @hi.enforce_collection_is_open.should == exp
        @hi.errors.size.should == n
      end
    end

    describe "check_version_if_license_changed()" do

      before(:each) do
        # Setup failing conditions.
        @hi.stub(:is_initial_version).and_return(false)
        @hi.stub(:license).and_return('A')
        @hi.stub(:prior_license).and_return('B')
        @hi.stub(:version_significance).and_return(:minor)
        # Lambdas to check for errors.
        @assert_no_errors = lambda { @hi.errors.messages.keys.should == [] }
        @assert_no_errors.call
      end

      it "can produce a version error" do
        @hi.check_version_if_license_changed
        @hi.errors.messages.keys.should == [:version]
      end

      it "initial version: cannot produce a version error" do
        @hi.stub(:is_initial_version).and_return(true)
        @hi.check_version_if_license_changed
        @assert_no_errors.call
      end

      it "license was not changed: cannot produce a version error" do
        @hi.stub(:prior_license).and_return(@hi.license)
        @hi.check_version_if_license_changed
        @assert_no_errors.call
      end

      it "version is major: cannot produce a version error" do
        @hi.stub(:version_significance).and_return(:major)
        @hi.check_version_if_license_changed
        @assert_no_errors.call
      end

    end

    describe "check_visibility_not_reduced()" do

      before(:each) do
        # Setup failing conditions.
        @hi.stub(:is_initial_version).and_return(false)
        @hi.stub(:visibility).and_return(['stanford'])
        @hi.stub(:prior_visibility).and_return('world')
        # Lambdas to check for errors.
        @assert_no_errors = lambda { @hi.errors.messages.keys.should == [] }
        @assert_no_errors.call
      end

      it "can produce a version error" do
        @hi.check_visibility_not_reduced
        @hi.errors.messages.keys.should == [:visibility]
      end

      it "initial version: cannot produce a visibility error" do
        @hi.stub(:is_initial_version).and_return(true)
        @hi.check_visibility_not_reduced
        @assert_no_errors.call
      end

      it "visibility was not changed: cannot produce a visibility error" do
        @hi.stub(:prior_visibility).and_return(@hi.visibility.first)
        @hi.check_visibility_not_reduced
        @assert_no_errors.call
      end

      it "visibility was expanded: cannot produce a visibility error" do
        @hi.stub(:visibility).and_return(['world'])
        @hi.stub(:prior_visibility).and_return('stanford')
        @hi.check_visibility_not_reduced
        @assert_no_errors.call
      end

    end

  end

  it "can exercise discovery_roles()" do
    Hydrus::Item.discovery_roles.should be_instance_of(Hash)
  end

  it "can exercise tracked_fields()" do
    @hi.tracked_fields.should be_an_instance_of(Hash)
  end

  describe "is_submittable_for_approval()" do

    it "if item is not a draft, should return false" do
      # Normally this would lead to a true result.
      @hi.stub(:requires_human_approval).and_return('yes')
      @hi.stub('validate!').and_return(true)
      # But since the item is not a draft, we expect false.
      @hi.stub(:object_status).and_return('returned')
      @hi.is_submittable_for_approval.should == false
    end

    it "if item does not require human approval, should return false" do
      # Normally this would lead to a true result.
      @hi.stub(:object_status).and_return('draft')
      @hi.stub('validate!').and_return(true)
      # But since the item does not require human approval, we expect false.
      @hi.stub(:requires_human_approval).and_return('no')
      @hi.is_submittable_for_approval.should == false
    end

    it "otherwise, should return the value of validate!" do
      @hi.stub(:object_status).and_return('draft')
      @hi.stub(:requires_human_approval).and_return('yes')
      [true, false, true, false].each do |exp|
        @hi.stub('validate!').and_return(exp)
        @hi.is_submittable_for_approval.should == exp
      end
    end

  end

  it "is_awaiting_approval() should return true object_status has expected value" do
    tests = {
      'awaiting_approval' => true,
      'returned'          => false,
      'draft'             => false,
      'published'         => false,
    }
    tests.each do |status, exp|
      @hi.stub(:object_status).and_return(status)
      @hi.is_awaiting_approval.should == exp
    end
  end

  it "is_returned() should return true object_status has expected value" do
    tests = {
      'awaiting_approval' => false,
      'returned'          => true,
      'draft'             => false,
      'published'         => false,
    }
    tests.each do |status, exp|
      @hi.stub(:object_status).and_return(status)
      @hi.is_returned.should == exp
    end
  end

  describe "is_approvable()" do

    it "item not awaiting approval: should always return false" do
      @hi.stub(:is_awaiting_approval).and_return(false)
      @hi.should_not_receive('validate!')
      @hi.is_approvable.should == false
    end

    it "item not awaiting approval: should return value of validate!" do
      @hi.stub(:is_awaiting_approval).and_return(true)
      [true, false].each do |exp|
        @hi.stub('validate!').and_return(exp)
        @hi.is_approvable.should == exp
      end
    end

  end

  it "is_disapprovable() should return the value of is_awaiting_approval()" do
    [true, false].each do |exp|
      @hi.stub(:is_awaiting_approval).and_return(exp)
      @hi.is_disapprovable.should == exp
    end
  end

  describe "is_resubmittable()" do

    it "item not returned: should always return false" do
      @hi.stub(:is_returned).and_return(false)
      @hi.should_not_receive('validate!')
      @hi.is_resubmittable.should == false
    end

    it "item not returned: should return value of validate!" do
      @hi.stub(:is_returned).and_return(true)
      [true, false].each do |exp|
        @hi.stub('validate!').and_return(exp)
        @hi.is_resubmittable.should == exp
      end
    end

  end

  it "is_destroyable() should return the negative of is_published" do
    @hi.stub(:is_published).and_return(false)
    @hi.is_destroyable.should == true
    @hi.stub(:is_published).and_return(true)
    @hi.is_destroyable.should == false
  end

  describe "is_publishable()" do

    it "invalid object: should always return false" do
      # If the item were valid, this setup would cause the method to return true.
      @hi.stub(:requires_human_approval).and_return('no')
      @hi.stub(:is_draft).and_return(true)
      # But it's not valid, so we should get false.
      @hi.stub('validate!').and_return(false)
      @hi.is_publishable.should == false
    end

    it "valid object: requires approval: should return value of is_awaiting_approval()" do
      @hi.stub('validate!').and_return(true)
      @hi.stub(:requires_human_approval).and_return('yes')
      [true, false, true, false].each do |exp|
        @hi.stub(:is_awaiting_approval).and_return(exp)
        @hi.is_publishable.should == exp
      end
    end

    it "valid object: does not require approval: should return value of is_draft()" do
      @hi.stub('validate!').and_return(true)
      @hi.stub(:requires_human_approval).and_return('no')
      [true, false, true, false].each do |exp|
        @hi.stub(:is_draft).and_return(exp)
        @hi.is_publishable.should == exp
      end
    end

  end

  describe "is_assemblable()" do

    it "unpublished item: should always return false" do
      @hi.stub(:is_published).and_return(false)
      @hi.should_not_receive('validate!')
      @hi.is_assemblable.should == false
    end

    it "published item: should return value of validate!" do
      @hi.stub(:is_published).and_return(true)
      [true, false].each do |exp|
        @hi.stub('validate!').and_return(exp)
        @hi.is_assemblable.should == exp
      end
    end

  end

  describe "publish_directly()" do

    it "item is not publishable: should raise exception" do
      @hi.stub(:is_publishable).and_return(false)
      expect { @hi.publish_directly }.to raise_exception(@cannot_do_regex)
    end

    it "item is publishable: should call the expected methods" do
      @hi.stub(:is_publishable).and_return(true)
      @hi.should_receive(:complete_workflow_step).with('submit')
      @hi.should_receive(:do_publish)
      @hi.publish_directly
    end

  end

  describe "do_publish()" do

    it "should call expected methods and set labels, status, and events" do
      # Set up object title.
      exp = 'foobar title'
      @hi.stub(:title).and_return(exp)
      # Stub method calls.
      @hi.should_receive(:complete_workflow_step).with('approve')
      @hi.should_not_receive(:close_version)
      @hi.should_receive(:start_common_assembly)
      # Before-assertions.
      @hi.is_initial_version.should == true
      @hi.publish_time.should be_blank
      @hi.initial_publish_time.should be_blank
      @hi.get_hydrus_events.size.should == 0
      # Run it, and make after-assertions.
      @hi.do_publish
      @hi.label.should == exp
      @hi.publish_time.should_not be_blank
      @hi.initial_publish_time.should_not be_blank
      @hi.object_status.should == 'published'
      @hi.get_hydrus_events.first.text.should =~ /\AItem published: v\d/
    end

    it "should close_version() if the object is not an initial version" do
      @hi.stub(:complete_workflow_step)
      @hi.stub(:start_common_assembly)
      @hi.stub(:is_initial_version).and_return(false)
      @hi.should_receive(:close_version)
      @hi.do_publish
    end

  end

  describe "submit_for_approval()" do

    it "item is not submittable: should raise exception" do
      @hi.stub(:is_submittable_for_approval).and_return(false)
      expect { @hi.submit_for_approval }.to raise_exception(@cannot_do_regex)
    end

    it "item is submittable: should set status and call expected methods" do
      @hi.stub(:is_submittable_for_approval).and_return(true)
      @hi.should_receive(:complete_workflow_step).with('submit')
      @hi.submit_for_approval_time.should be_blank
      @hi.object_status.should_not == 'awaiting_approval'
      @hi.submit_for_approval
      @hi.submit_for_approval_time.should_not be_blank
      @hi.object_status.should == 'awaiting_approval'
    end

  end

  describe "approve()" do

    it "item is not approvable: should raise exception" do
      @hi.stub(:is_approvable).and_return(false)
      expect { @hi.approve }.to raise_exception(@cannot_do_regex)
    end

    it "item is approvable: should remove disapproval_reason and call expected methods" do
      @hi.stub(:is_approvable).and_return(true)
      @hi.should_receive(:do_publish)
      @hi.disapproval_reason = 'some reason'
      @hi.approve
      @hi.disapproval_reason.should == nil
    end

  end

  describe "disapprove()" do

    it "item is not disapprovable: should raise exception" do
      reason = 'some reason'
      @hi.stub(:is_disapprovable).and_return(false)
      expect { @hi.disapprove(reason) }.to raise_exception(@cannot_do_regex)
    end

    it "item is disapprovable: should set disapproval_reason and object status and call expected methods" do
      reason = 'some reason'
      @hi.stub(:is_disapprovable).and_return(true)
      @hi.should_receive(:send_object_returned_email_notification)
      @hi.disapproval_reason.should == nil
      @hi.object_status.should_not == 'returned'
      @hi.disapprove(reason)
      @hi.disapproval_reason.should == reason
      @hi.object_status.should == 'returned'
    end

  end

  describe "resubmit()" do

    it "item is not resubmittable: should raise exception" do
      @hi.stub(:is_resubmittable).and_return(false)
      expect { @hi.resubmit }.to raise_exception(@cannot_do_regex)
    end

    it "item is resubmittable: should remove disapproval_reason, set object status, and call expected methods" do
      @hi.stub(:is_resubmittable).and_return(true)
      @hi.disapproval_reason = 'some reason'
      @hi.object_status.should_not == 'awaiting_approval'
      @hi.resubmit
      @hi.disapproval_reason.should == nil
      @hi.object_status.should == 'awaiting_approval'
    end

  end

  describe "open_new_version()" do

    # More significant testing is done at the integration level.

    it "should raise exception if item is initial version" do
      @hi.stub(:is_accessioned).and_return(false)
      expect { @hi.open_new_version }.to raise_exception(@cannot_do_regex)
    end

  end

  describe "close_version()" do

    it "should raise exception if item is initial version" do
      @hi.stub(:is_initial_version).and_return(true)
      expect { @hi.close_version }.to raise_exception(@cannot_do_regex)
    end

  end

  it "should indicate no files have been uploaded yet" do
    @hi.files_uploaded?.should == false
  end

  it "should indicate that release settings have not been reviewed yet" do
    @hi.reviewed_release_settings?.should == false
    @hi.reviewed_release_settings="true"
    @hi.reviewed_release_settings?.should == true
  end

  it "should indicate that terms of deposit have not been accepted yet" do
    @hi.terms_of_deposit_accepted?.should == false
  end

  it "should indicate if we do not require terms acceptance if user already accepted terms" do
    @hi.stub(:accepted_terms_of_deposit).and_return(true)
    @hi.requires_terms_acceptance('archivist1').should be false
  end

  it "should indicate if we do require terms acceptance if user has never accepted terms on another item in the same collection" do
    @coll=Hydrus::Collection.new
    @coll.stub(:users_accepted_terms_of_deposit).and_return({'archivist3'=>'10-12-2008 00:00:00','archivist4'=>'10-12-2009 00:00:05'})
    @hi.stub(:accepted_terms_of_deposit).and_return(false)
    @hi.stub(:collection).and_return(@coll)
    @hi.requires_terms_acceptance('archivist1').should be true
  end

  it "should indicate if we do require terms acceptance if user already accepted terms on another item in the same collection, but it was more than 1 year ago" do
    @coll=Hydrus::Collection.new
    @coll.stub(:users_accepted_terms_of_deposit).and_return({'archivist1'=>'10-12-2008 00:00:00','archivist2'=>'10-12-2009 00:00:05'})
    @hi.stub(:accepted_terms_of_deposit).and_return(false)
    @hi.stub(:collection).and_return(@coll)
    @hi.requires_terms_acceptance('archivist1').should be true
  end

  it "should indicate if we do not require terms acceptance if user already accepted terms on another item in the same collection, and it was less than 1 year ago" do
    @coll=Hydrus::Collection.new
    @coll.stub(:users_accepted_terms_of_deposit).and_return({'archivist1'=>Time.now.in_time_zone - 364.days,'archivist2'=>'10-12-2009 00:00:05'})
    @hi.stub(:accepted_terms_of_deposit).and_return(false)
    @hi.stub(:collection).and_return(@coll)
    @hi.requires_terms_acceptance('archivist1').should be false
  end

  it "should accept the terms of deposit for a user" do
    @coll=Hydrus::Collection.new
    Hydrus::Authorizable.stub(:can_edit_item).and_return(true)
    @coll.stub(:accept_terms_of_deposit)
    @hi.stub(:collection).and_return(@coll)
    @hi.terms_of_deposit_accepted?.should == false
    @hi.accepted_terms_of_deposit.should_not == 'true'
    @hi.accept_terms_of_deposit('archivist1')
    @hi.accepted_terms_of_deposit.should == 'true'
    @hi.terms_of_deposit_accepted?.should == true
  end

  describe "embargo_date_is_well_formed()" do

    it "should be driven by @embargo_date_was_malformed instance variable" do
      k = :embargo_date
      [true, false].each do |exp|
        @hi.errors.messages.keys.include?(k).should == false
        @hi.instance_variable_set('@embargo_date_was_malformed', exp)
        @hi.embargo_date_is_well_formed
        @hi.errors.messages.keys.include?(k).should == exp
        @hi.errors.clear
      end
    end

  end

  it "requires_human_approval() should delegate to the collection" do
    ["yes", "no", "yes"].each { |exp|
      @hi.stub_chain(:collection, :requires_human_approval).and_return(exp)
      @hi.requires_human_approval.should == exp
    }
  end

  describe "version getters and setters" do

    before(:each) do
      vs = [
        '<version tag="1.0.0" versionId="1"><description>Blah 1.0.0</description></version>',
        '<version tag="2.0.0" versionId="2"><description>Blah 2.0.0</description></version>',
        '<version tag="2.1.0" versionId="3"><description>Blah 2.1.0</description></version>',
        '<version tag="3.0.0" versionId="4"><description>Blah 3.0.0</description></version>',
        '<version tag="3.0.1" versionId="5"><description>Blah 3.0.1</description></version>',
      ]
      @stub_vm = lambda { |v|
        tags = %w(1.0.0 2.0.0 2.1.0 3.0.0 3.0.1)
        n = tags.find_index(v)
        xml = [
          '<?xml version="1.0"?>',
          '<versionMetadata objectId="druid:oo000oo0001">',
          vs[0..n],
          '</versionMetadata>',
        ]
        vm = Dor::VersionMetadataDS.from_xml(xml.flatten.join)
        vm.stub(:pid).and_return('druid:oo000oo0001')
        @hi.stub(:versionMetadata).and_return(vm)
        @hi.datastreams['versionMetadata'] = vm
      }
    end

    it "basic getters should return expected attributes of the current version" do
      @stub_vm.call('1.0.0')
      @hi.version_id.should == '1'
      @hi.version_tag.should == 'v1.0.0'
      @hi.version_description.should == 'Blah 1.0.0'
      @stub_vm.call('2.1.0')
      @hi.version_id.should == '3'
      @hi.version_tag.should == 'v2.1.0'
      @hi.version_description.should == 'Blah 2.1.0'
    end

    it "is_initial_version() should return true only for the first version" do
      @stub_vm.call('1.0.0')
      @hi.is_initial_version.should == true
      @stub_vm.call('2.0.0')
      @hi.is_initial_version.should == false
      @stub_vm.call('2.1.0')
      @hi.is_initial_version.should == false
    end

    it "version_significance() should return :major, :minor, or :admin" do
      tests = {
        '1.0.0' => :major,
        '2.0.0' => :major,
        '2.1.0' => :minor,
        '3.0.0' => :major,
        '3.0.1' => :admin,
      }
      tests.each do |v, exp|
        @stub_vm.call(v)
        @hi.version_significance.should == exp
      end
    end

    it "version_significance=() should modify the version tag as expected" do
      @stub_vm.call('2.1.0')
      tests = {
        'major' => 'v3.0.0',
        'admin' => 'v2.0.1',
        'minor' => 'v2.1.0',
      }
      tests.each do |sig, exp|
        @hi.version_significance = sig
        @hi.version_tag.should == exp
      end
    end

    it "version_description=() modifies the description" do
      @stub_vm.call('2.1.0')
      @hi.version_description.should == 'Blah 2.1.0'
      exp = 'blah blah blah!!'
      @hi.version_description = exp
      @hi.version_description.should == exp
    end

  end
end
