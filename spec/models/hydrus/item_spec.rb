require 'spec_helper'

RSpec.describe Hydrus::Item, type: :model do
  let(:item) { Hydrus::Item.new }
  let(:collection) { Hydrus::Collection.new }

  before do
    @cannot_do_regex = /\ACannot perform action/
    allow(item).to receive(:collection).and_return(collection)
  end

  describe '#files' do
    subject { item.files }

    it 'should retrieve ObjectFiles from the database' do
      expect(subject).to be_a ActiveRecord::Relation
      expect(subject.where_values_hash).to eq 'pid' => item.pid
      expect(subject.order_values).to eq ['weight ASC,label ASC,file ASC']
    end
  end

  describe '#contributors' do
    let(:xml) do
      <<-eos
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
    end

    before do
      @rattr = 'authority="marcrelator" type="text"'

      item.datastreams['descMetadata'] = Hydrus::DescMetadataDS.from_xml(xml)
    end

    it 'contributors()' do
      expect(item.contributors.length).to eq(3)
      item.contributors.all? { |c| expect(c).to be_instance_of(Hydrus::Contributor) }
    end

    it 'insert_contributor()' do
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
      item.insert_contributor('FooBar', 'corporate_sponsor')
      item.insert_contributor
      new_xml = xml.sub(/<\/mods>/, extra_xml + '</mods>')
      expect(item.descMetadata.ng_xml).to be_equivalent_to(new_xml)
    end

    it 'contributors=()' do
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
      item.contributors = {
        '0' => { 'name' => 'AAA', 'role_key' => 'corporate_author' },
        '1' => { 'name' => 'BBB', 'role_key' => 'personal_author' },
      }
      expect(item.descMetadata.ng_xml).to be_equivalent_to(exp)
    end
  end
  describe 'dates' do
    before do
    end
    it 'single_date? should be true for a normal date_created' do
      xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated>
          2013
          </dateCreated>
          </originInfo>
        </mods>
      eos
      item.datastreams['descMetadata'] = Hydrus::DescMetadataDS.from_xml(xml)
      expect(item.single_date?).to be_truthy
    end
    it 'should handle an older item with no date created' do
      xml = <<-eos

      <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
        <titleInfo>
          <title>Commencement addresses</title>
        </titleInfo>

        <abstract>Transcripts of addresses delivered at Stanford commencement ceremonies.</abstract>
        <note type="preferred citation" displayLabel="Preferred Citation">Stanford University Commencement Collection (1892- ). Stanford Digital Repository. Available at http://purl.stanford.edu/mp840zw9344.</note>
        <note type="citation/reference" displayLabel="Related Publication"/>
        <note type="contact" displayLabel="Contact">archivesref@stanford.edu</note>

        <relatedItem>
          <titleInfo>
            <title>Finding Aid</title>
          </titleInfo>
          <location>
            <url>http://www.oac.cdlib.org/findaid/ark:/13030/c8vq322c</url>
          </location>
        </relatedItem><relatedItem><titleInfo><title>List of commencement speakers</title></titleInfo><location><url>http://library.stanford.edu/spc/university-archives/stanford-history/commencement-addresses</url></location></relatedItem>
      <name type="corporate"><namePart>Stanford University.</namePart><role><roleTerm authority="marcrelator" type="text">Sponsor</roleTerm></role></name><subject><topic>Stanford University--Commencement</topic></subject><subject><topic>Stanford University--Invited speakers</topic></subject></mods>
      eos
      item.datastreams['descMetadata'] = Hydrus::DescMetadataDS.from_xml(xml)
      expect(item.dates[:date_created_approximate]).to be_falsey
    end
    it 'date_range? should be true for a date range' do
      xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" point="start" keyDate="yes">2005-04</dateCreated>
          <dateCreated encoding="w3cdtf" point="end">2005-05</dateCreated>
          </originInfo>
        </mods>
      eos
      item.datastreams['descMetadata'] = Hydrus::DescMetadataDS.from_xml(xml)
      expect(item.single_date?).to be_falsey
      expect(item.date_range?).to be_truthy
    end

    describe '#undated?' do
      let(:xml) do
        <<-eos
          <mods xmlns="http://www.loc.gov/mods/v3">
            <originInfo>
            <dateCreated >Undated</dateCreated>
            </originInfo>
          </mods>
        eos
      end
      let(:desc_md) { Hydrus::DescMetadataDS.from_xml(xml) }
      before { item.datastreams['descMetadata'] = desc_md }

      it 'is true for an undated item' do
        expect(item.undated?).to be_truthy
        expect(item.single_date?).to be_falsey
        expect(item.date_range?).to be_falsey
      end
    end

    describe '#dates' do
      subject { item.dates }

      let(:desc_md) { Hydrus::DescMetadataDS.from_xml(xml) }
      before { item.datastreams['descMetadata'] = desc_md }

      context 'with a range' do
        let(:xml) do
          <<-eos
            <mods xmlns="http://www.loc.gov/mods/v3">
              <originInfo>
              <dateCreated encoding="w3cdtf" point="start" keyDate="yes" qualifier="approximate">2005-04</dateCreated>
              <dateCreated encoding="w3cdtf" point="end">2005-05</dateCreated>
              </originInfo>
            </mods>
          eos
        end

        it 'creates a dates hash with the data to populate the form' do
          expect(subject[:date_range_start]).to eq(['2005-04'])
          expect(subject[:date_range_end]).to eq(['2005-05'])
          expect(subject[:date_range_start_approximate]).to be_truthy
          expect(subject[:date_range_end_approximate]).to be_falsey
        end
      end
      context 'when undated' do
        let(:xml) do
          <<-eos
            <mods xmlns="http://www.loc.gov/mods/v3">
              <originInfo>
              <dateCreated >Undated</dateCreated>
              </originInfo>
            </mods>
          eos
        end

        it 'creates a dates hash with the data to populate the form' do
          expect(subject[:date_range_start]).to eq([])
          expect(subject[:date_range_end]).to eq([])
          expect(subject[:date_range_start_approximate]).to be_falsey
          expect(subject[:date_range_end_approximate]).to be_falsey
          expect(subject[:undated]).to be_truthy
        end
      end

      context 'when there is a specific date' do
        let(:xml) do
          <<-eos
            <mods xmlns="http://www.loc.gov/mods/v3">
              <originInfo>
              <dateCreated>2013</dateCreated>
              </originInfo>
            </mods>
          eos
        end

        it 'creates a dates hash with the data to populate the form' do
          expect(subject[:date_created]).to eq(['2013'])
          expect(subject[:date_range_start]).to eq([])
          expect(subject[:date_range_end]).to eq([])
          expect(subject[:date_range_start_approximate]).to be_falsey
          expect(subject[:date_range_end_approximate]).to be_falsey
          expect(subject[:undated]).to be_falsey
        end
      end
    end
  end

  describe 'date=' do
    it 'should clear out existing dates and set a single date' do
      hash = {
        date_created: ['2013'],
        date_created_approximate: 'hi',
        date_type: 'single'
      }
      item.dates = hash
      new_hash = item.dates
      expect(new_hash[:date_created]).to eq(['2013'])
      expect(item.single_date?).to be_truthy
    end
  end
  describe 'date_display' do
    it 'should render a date range with approximate dates' do
      xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" point="start" keyDate="yes" qualifier="approximate">2005-04</dateCreated>
          <dateCreated encoding="w3cdtf" point="end" qualifier="approximate">2005-05</dateCreated>
          </originInfo>
        </mods>
      eos
      item.datastreams['descMetadata'] = Hydrus::DescMetadataDS.from_xml(xml)
      expect(item.date_display).to eq('[ca. 2005-04 - ca. 2005-05]')
    end
    it 'should render a date range with one approximate date' do
      xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" point="start" keyDate="yes" qualifier="approximate">2005-04</dateCreated>
          <dateCreated encoding="w3cdtf" point="end">2005-05</dateCreated>
          </originInfo>
        </mods>
      eos
      item.datastreams['descMetadata'] = Hydrus::DescMetadataDS.from_xml(xml)
      expect(item.date_display).to eq('[ca. 2005-04] to 2005-05')
    end
    it 'should render a date range with approximate dates' do
      xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" keyDate="yes" qualifier="approximate">2005-04</dateCreated>
          </originInfo>
        </mods>
      eos
      item.datastreams['descMetadata'] = Hydrus::DescMetadataDS.from_xml(xml)
      expect(item.date_display).to eq('[ca. 2005-04]')
    end
    it 'should work with no date present' do
      xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated></dateCreated>
          </originInfo>
        </mods>
      eos
      item.datastreams['descMetadata'] = Hydrus::DescMetadataDS.from_xml(xml)
      expect(item.date_display).to eq('')
    end
  end
  describe 'roleMetadata in the item', integration: true do
    subject { Hydrus::Item.find('druid:bb123bb1234') }
    it 'should have a roleMetadata datastream' do
      expect(subject.roleMetadata).to be_an_instance_of(Hydrus::RoleMetadataDS)
      expect(subject.item_depositor_id).to eq('archivist1')
      expect(subject.item_depositor_name).to eq('Archivist, One')
    end
  end

  describe 'keywords' do
    before do
      @mods_start = '<mods xmlns="http://www.loc.gov/mods/v3">'
      xml = <<-EOF
        #{@mods_start}
          <subject><topic>divorce</topic></subject>
          <subject><topic>marriage</topic></subject>
        </mods>
      EOF
      @dsdoc = Hydrus::DescMetadataDS.from_xml(xml)
      item.datastreams['descMetadata'] = @dsdoc
    end

    it 'keywords() should return expected values' do
      expect(item.keywords).to eq(%w(divorce marriage))
    end

    it 'keywords= should rewrite all <subject> nodes' do
      item.keywords = ' foo , bar , quux  '
      expect(@dsdoc.ng_xml).to be_equivalent_to <<-EOF
        #{@mods_start}
          <subject><topic>foo</topic></subject>
          <subject><topic>bar</topic></subject>
          <subject><topic>quux</topic></subject>
        </mods>
      EOF
    end

    it 'keywords= should not modify descMD if the keywords are same as existing' do
      kws = %w(foo bar)
      allow(item).to receive(:keywords).and_return(kws)
      expect(item).not_to receive(:descMetadata)
      item.keywords = kws.join(',')
    end
  end

  describe 'visibility()' do
    let(:mock_groups) { [double(text: 'foo'), double(text: 'bar')] }
    it 'should return [] for initial visibility' do
      expect(item.visibility).to eq([])
    end

    context 'for an embargoed item' do
      before do
        allow(item).to receive(:is_embargoed).and_return(true)
      end

      it 'returns ["world"] when the item is world visible' do
        allow(item).to receive_message_chain('embargoMetadata', :has_world_read_node).and_return(true)
        expect(item.visibility).to eq(['world'])
      end

      it 'returns an array of groups if the item is visible to specific groups' do
        allow(item).to receive_message_chain('embargoMetadata', :has_world_read_node).and_return(false)
        allow(item).to receive_message_chain('embargoMetadata', :group_read_nodes).and_return(mock_groups)
        expect(item.visibility).to eq %w(foo bar)
      end
    end

    context 'for an unembargoed item' do
      before do
        allow(item).to receive(:is_embargoed).and_return(false)
      end

      it 'returns ["world"] when the item is world visible' do
        allow(item).to receive_message_chain('rightsMetadata', :has_world_read_node).and_return(true)
        expect(item.visibility).to eq(['world'])
      end

      it 'returns an array of groups if the item is visible to specific groups' do
        allow(item).to receive_message_chain('rightsMetadata', :has_world_read_node).and_return(false)
        allow(item).to receive_message_chain('rightsMetadata', :group_read_nodes).and_return(mock_groups)
        expect(item.visibility).to eq %w(foo bar)
      end
    end
  end

  describe 'embarg_visib=()' do
    let(:embargo_date) { '2012-02-28T08:00:00Z' }

    before do
      # This enables the tests to run in a timezone other than Pacific.
      allow(HyTime).to receive(:datetime).with('2012-02-28', from_localzone: true).and_return(embargo_date)
    end

    let(:machine_world) { '<machine><world/></machine>' }
    let(:machine_stanford) { '<machine><group>stanford</group></machine>' }
    let(:discover_world) { %Q[<access type="discover">#{machine_world}</access>] }
    let(:read_stanford) { %Q[<access type="read">#{machine_stanford}</access>] }
    let(:read_world) { %Q[<access type="read">#{machine_world}</access>] }
    let(:rights_metadata_start) { %Q[<rightsMetadata>] }
    let(:rights_metadata_end) {
      '<use><human type="useAndReproduction"/></use>' +
        '</rightsMetadata>'
    }

    let(:item) { Hydrus::Item.new }

    let(:embargo_visibility_attributes) do
      {
        'embargoed'  => embargoed,
        'date'       => date,
        'visibility' => visibility
      }
    end

    context 'when is_embargoed is true' do
      let(:embargoed) { 'yes' }
      let(:date) { HyTime.date_display(embargo_date) }

      let(:machine_embargo) { %Q[<machine><embargoReleaseDate>#{embargo_date}</embargoReleaseDate><none/></machine>] }
      let(:read_embargo) { %Q[<access type="read">#{machine_embargo}</access>] }

      let(:twenty_percent) { '<twentyPctVisibilityStatus/><twentyPctVisibilityReleaseDate/>' }
      let(:em_end) { %Q[</embargoMetadata>] }
      let(:em_date) { %Q[<releaseDate>#{embargo_date}</releaseDate>] }
      let(:em_world) { %Q[<releaseAccess>#{discover_world}#{read_world}</releaseAccess>] }
      let(:em_stanf) { %Q[<releaseAccess>#{discover_world}#{read_stanford}</releaseAccess>] }
      let(:em_start) { %Q[<embargoMetadata><status>embargoed</status>#{em_date}] }

      let(:rm_emb) { noko_doc([rights_metadata_start, discover_world, read_embargo, rights_metadata_end].join) }

      context 'and visibility is world' do
        let(:visibility) { 'world' }
        let(:expected_em) { noko_doc([em_start, em_world, twenty_percent, em_end].join) }

        it 'returns the expected XML' do
          item.embarg_visib = embargo_visibility_attributes
          expect(item.rightsMetadata.ng_xml).to  be_equivalent_to(rm_emb)
          expect(item.embargoMetadata.ng_xml).to be_equivalent_to(expected_em)
        end
      end

      context 'and visibility is stanford' do
        let(:visibility) { 'stanford' }
        let(:expected_em) { noko_doc([em_start, em_stanf, twenty_percent, em_end].join) }

        it 'returns the expected XML' do
          item.embarg_visib = embargo_visibility_attributes
          expect(item.rightsMetadata.ng_xml).to  be_equivalent_to(rm_emb)
          expect(item.embargoMetadata.ng_xml).to be_equivalent_to(expected_em)
        end
      end
    end

    context 'when is_embargoed is false' do
      let(:embargoed) { 'no' }
      let(:date) { '' }

      context 'and visibility is world' do
        let(:visibility) { 'world' }
        let(:rm_world) { noko_doc([rights_metadata_start, discover_world, read_world, rights_metadata_end].join) }
        it 'returns the expected XML' do
          expect(item.embargoMetadata).to receive(:delete)
          item.embarg_visib = embargo_visibility_attributes
          expect(item.rightsMetadata.ng_xml).to be_equivalent_to(rm_world)
        end
      end

      context 'and visibilty is stanford' do
        let(:visibility) { 'stanford' }
        let(:rm_stanf) { noko_doc([rights_metadata_start, discover_world, read_stanford, rights_metadata_end].join) }

        it 'returns the expected XML' do
          expect(item.embargoMetadata).to receive(:delete)
          item.embarg_visib = embargo_visibility_attributes
          expect(item.rightsMetadata.ng_xml).to be_equivalent_to(rm_stanf)
        end
      end
    end
  end

  describe 'embargo' do
    it 'is_embargoed should return true if the Item has a non-blank embargo date' do
      tests = {
        ''                     => false,
        nil                    => false,
        '2012-08-30T08:00:00Z' => true,
      }
      tests.each do |dt, exp|
        allow(item).to receive(:embargo_date).and_return(dt)
        expect(item.is_embargoed).to eq(exp)
      end
    end

    describe 'embargo_date() and embargo_date=()' do
      it 'getter should return value from embargoMetadata' do
        exp = 'foo release date'
        allow(item).to receive_message_chain(:embargoMetadata, :release_date).and_return(exp)
        expect(item.embargo_date).to eq(exp)
      end

      describe 'setter: with valid date' do
        let(:rd_dt) { '2012-08-30T08:00:00+00:00' }
        before do
          # This enables the tests to run in a timezone other than Pacific.
          allow(HyTime).to receive(:datetime).with('2012-08-30', from_localzone: true).and_return(rd_dt)
        end

        it 'store date in UTC in both embargoMD and rightsMD' do
          item.embargo_date = '2012-08-30'
          expect(item.embargo_date).to eq(rd_dt)
          expect(item.rmd_embargo_release_date).to eq(rd_dt)
          expect(item.embargoMetadata.status).to eq('embargoed')
          expect(item.instance_variable_get('@embargo_date_was_malformed')).to eq(nil)
        end
      end

      describe 'setter: with invalid date' do
        it 'blank or nil: delete embargoMetadata; do not set instance var' do
          expect(item.embargoMetadata).to receive(:delete)
          dt = rand() < 0.5 ? '' : nil
          item.embargo_date = dt
          expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).to eq(nil)
          expect(item.instance_variable_get('@embargo_date_was_malformed')).to eq(nil)
        end

        it 'malformed: do not delete embargoMetadata; set instance var' do
          expect(item.embargoMetadata).not_to receive(:delete)
          item.embargo_date = 'blah'
          expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).to eq(nil)
          expect(item.instance_variable_get('@embargo_date_was_malformed')).to eq(true)
        end
      end
    end

    describe 'beginning_of_embargo_range()' do
      it 'initial_submitted_for_publish_time missing: should return now_datetime()' do
        exp = 'foo bar'
        allow(HyTime).to receive(:now_datetime).and_return(exp)
        allow(item).to receive(:initial_submitted_for_publish_time).and_return(nil)
        expect(item.beginning_of_embargo_range).to eq(exp)
      end

      it 'initial_submitted_for_publish_time present: should return it' do
        exp = 'foo bar blah'
        allow(item).to receive(:initial_submitted_for_publish_time).and_return(exp)
        expect(item.beginning_of_embargo_range).to eq(exp)
      end
    end

    describe 'end_of_embargo_range()' do
      it "should get the end date range properly based on the collection's APO" do
        t = 'T00:00:00Z'
        allow(item).to receive(:beginning_of_embargo_range).and_return("2012-08-01#{t}")
        tests = {
          '6 months' => "2013-02-01#{t}",
          '1 year'   => "2013-08-01#{t}",
          '5 years'  => "2017-08-01#{t}",
        }
        tests.each do |emb, exp|
          allow(item).to receive_message_chain(:collection, :embargo_terms).and_return(emb)
          expect(item.end_of_embargo_range).to eq(exp)
        end
      end
    end

    describe 'embargo_can_be_changed()' do
      it 'Collection does not allow embargo variability: should return false' do
        expect(item).not_to receive(:is_initial_version)
        %w(none fixed).each do |opt|
          allow(collection).to receive(:embargo_option).and_return(opt)
          expect(item.embargo_can_be_changed).to eq(false)
        end
      end

      describe 'Collection allows embargo variability' do
        before do
          allow(collection).to receive(:embargo_option).and_return('varies')
        end

        it 'initial version: always true' do
          allow(item).to receive(:is_initial_version).and_return(true)
          expect(item).not_to receive(:is_embargoed)
          expect(item.embargo_can_be_changed).to eq(true)
        end

        it 'subsequent versions: not embargoed: always false' do
          allow(item).to receive(:is_initial_version).and_return(false)
          allow(item).to receive(:is_embargoed).and_return(false)
          expect(item).not_to receive(:end_of_embargo_range)
          expect(item.embargo_can_be_changed).to eq(false)
        end

        it 'subsequent versions: embargoed: true if end_of_embargo_range is in future' do
          allow(item).to receive(:is_initial_version).and_return(false)
          allow(item).to receive(:is_embargoed).and_return(true)
          tpast = HyTime.datetime(HyTime.now - 2.day)
          tfut  = HyTime.datetime(HyTime.now + 2.day)
          allow(item).to receive(:end_of_embargo_range).and_return(tpast)
          expect(item.embargo_can_be_changed).to eq(false)
          allow(item).to receive(:end_of_embargo_range).and_return(tfut)
          expect(item.embargo_can_be_changed).to eq(true)
        end
      end
    end
  end

  describe 'strip_whitespace_from_fields()' do
    before do
      xml = <<-eos
       <mods xmlns="http://www.loc.gov/mods/v3">
          <abstract>  Blah blah  </abstract>
          <titleInfo><title>  Learn VB in 21 Days  </title></titleInfo>
       </mods>
      eos
      dmd = Hydrus::DescMetadataDS.from_xml(xml)
      item = Hydrus::Item.new
      item.datastreams['descMetadata'] = dmd
    end

    it 'should be able to call method on a Hydrus::Item to remove whitespace' do
      a = item.abstract
      t = item.title
      item.strip_whitespace_from_fields([:abstract, :title])
      expect(item.abstract).to eq(a.strip)
      expect(item.title).to eq(t.strip)
    end
  end

  describe 'validations' do
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
      item.instance_variable_set('@should_validate', true)
    end

    it 'blank slate Item (should_validate=false) should include only two errors' do
      allow(item).to receive(:should_validate).and_return(false)
      expect(item.valid?).to eq(false)
      expect(item.errors.messages.keys).to include(*@exp[0..1])
    end

    it 'blank slate Item (should_validate=true) should include all errors' do
      expect(item.valid?).to eq(false)
      expect(item.errors.messages.keys).to include(*@exp)
    end

    describe 'embargo_date_in_range()' do
      it 'should not perform validation unless preconditions are met' do
        expect(item).not_to receive(:beginning_of_embargo_range)
        allow(item).to receive(:is_embargoed).and_return(false)
        item.embargo_date_in_range
      end

      it 'should add a validation error when embargo_date falls outside the embargo range' do
        # Set up beginning/end of embargo range.
        b   = '2012-02-01T08:00:00Z'
        e   = '2012-03-01T08:00:00Z'
        bdt = HyTime.datetime(b)
        edt = HyTime.datetime(e)
        allow(item).to receive(:beginning_of_embargo_range).and_return(bdt)
        allow(item).to receive(:end_of_embargo_range).and_return(edt)
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
        allow(item).to receive(:is_embargoed).and_return(true)
        k = :embargo_date
        dts.each do |dt, is_ok|
          expect(item.errors).not_to have_key(k)
          allow(item).to receive(k).and_return(HyTime.datetime(dt))
          item.embargo_date_in_range
          if is_ok
            expect(item.errors).not_to have_key(k)
          else
            expect(item.errors).to have_key(k)
            expect(item.errors.messages[k].first).to eq(exp_msg)
          end
          item.errors.clear
        end
      end
    end

    it 'fully populated Item should be valid' do
      dru = 'druid:ll000ll0001'
      allow(item).to receive(:enforce_collection_is_open).and_return(true)
      allow(item).to receive(:accepted_terms_of_deposit).and_return(true)
      allow(item).to receive(:reviewed_release_settings).and_return(true)
      @exp.each { |e| allow(item).to receive(e).and_return(dru) unless e == :contact }
      allow(item).to receive(:contact).and_return('test@test.com') # we need a valid email address
      allow(item).to receive(:contributors).and_return([Hydrus::Contributor.new(name: 'Some, person')]) # need at least one non-blank contributor
      allow(item).to receive(:keywords).and_return(%w(aaa bbb))
      allow(item).to receive(:dates).and_return({ date_created: '2011' })
      allow(item).to receive(:date_created).and_return('2011')
      allow(item).to receive(:single_date?).and_return true
      allow(item).to receive_message_chain([:collection, :embargo_option]).and_return('varies')
      if !item.valid?
        msg = item.errors.messages.map { |field, error|
          "#{field.to_s.humanize.capitalize} #{error.join(', ')}"
        }
        raise msg.join ', \n'
      end
      expect(item.valid?).to eq(true)
    end

    it 'enforce_collection_is_open() should return true only if the Item is in an open Collection' do
      n = 0
      [true, false, nil].each do |stub_val|
        c    = double('collection', is_open: stub_val)
        exp  = !(!stub_val)
        n   += 1 unless exp
        allow(item).to receive(:collection).and_return(c)
        expect(item.enforce_collection_is_open).to eq(exp)
        expect(item.errors.size).to eq(n)
      end
    end

    describe 'check_version_if_license_changed()' do
      before(:each) do
        # Setup failing conditions.
        allow(item).to receive(:is_initial_version).and_return(false)
        allow(item).to receive(:license).and_return('A')
        allow(item).to receive(:prior_license).and_return('B')
        allow(item).to receive(:version_significance).and_return(:minor)
        # Lambdas to check for errors.
        @assert_no_errors = lambda { expect(item.errors.messages.keys).to eq([]) }
        @assert_no_errors.call
      end

      it 'can produce a version error' do
        item.check_version_if_license_changed
        expect(item.errors.messages.keys).to eq([:version])
      end

      it 'initial version: cannot produce a version error' do
        allow(item).to receive(:is_initial_version).and_return(true)
        item.check_version_if_license_changed
        @assert_no_errors.call
      end

      it 'license was not changed: cannot produce a version error' do
        allow(item).to receive(:prior_license).and_return(item.license)
        item.check_version_if_license_changed
        @assert_no_errors.call
      end

      it 'version is major: cannot produce a version error' do
        allow(item).to receive(:version_significance).and_return(:major)
        item.check_version_if_license_changed
        @assert_no_errors.call
      end
    end

    describe 'check_visibility_not_reduced()' do
      before(:each) do
        # Setup failing conditions.
        allow(item).to receive(:is_initial_version).and_return(false)
        allow(item).to receive(:visibility).and_return(['stanford'])
        allow(item).to receive(:prior_visibility).and_return('world')
        # Lambdas to check for errors.
        @assert_no_errors = lambda { expect(item.errors.messages.keys).to eq([]) }
        @assert_no_errors.call
      end

      it 'can produce a version error' do
        item.check_visibility_not_reduced
        expect(item.errors.messages.keys).to eq([:visibility])
      end

      it 'initial version: cannot produce a visibility error' do
        allow(item).to receive(:is_initial_version).and_return(true)
        item.check_visibility_not_reduced
        @assert_no_errors.call
      end

      it 'visibility was not changed: cannot produce a visibility error' do
        allow(item).to receive(:prior_visibility).and_return(item.visibility.first)
        item.check_visibility_not_reduced
        @assert_no_errors.call
      end

      it 'visibility was expanded: cannot produce a visibility error' do
        allow(item).to receive(:visibility).and_return(['world'])
        allow(item).to receive(:prior_visibility).and_return('stanford')
        item.check_visibility_not_reduced
        @assert_no_errors.call
      end
    end
  end

  it 'can exercise discovery_roles()' do
    expect(Hydrus::Item.discovery_roles).to be_instance_of(Hash)
  end

  it 'can exercise tracked_fields()' do
    expect(item.tracked_fields).to be_an_instance_of(Hash)
  end

  describe 'is_submittable_for_approval()' do
    it 'if item is not a draft, should return false' do
      # Normally this would lead to a true result.
      allow(item).to receive(:requires_human_approval).and_return('yes')
      allow(item).to receive('validate!').and_return(true)
      # But since the item is not a draft, we expect false.
      allow(item).to receive(:object_status).and_return('returned')
      expect(item.is_submittable_for_approval).to eq(false)
    end

    it 'if item does not require human approval, should return false' do
      # Normally this would lead to a true result.
      allow(item).to receive(:object_status).and_return('draft')
      allow(item).to receive('validate!').and_return(true)
      # But since the item does not require human approval, we expect false.
      allow(item).to receive(:requires_human_approval).and_return('no')
      expect(item.is_submittable_for_approval).to eq(false)
    end

    it 'otherwise, should return the value of validate!' do
      allow(item).to receive(:object_status).and_return('draft')
      allow(item).to receive(:requires_human_approval).and_return('yes')
      [true, false, true, false].each do |exp|
        allow(item).to receive('validate!').and_return(exp)
        expect(item.is_submittable_for_approval).to eq(exp)
      end
    end
  end

  it 'is_awaiting_approval() should return true object_status has expected value' do
    tests = {
      'awaiting_approval' => true,
      'returned'          => false,
      'draft'             => false,
      'published'         => false,
    }
    tests.each do |status, exp|
      allow(item).to receive(:object_status).and_return(status)
      expect(item.is_awaiting_approval).to eq(exp)
    end
  end

  it 'is_returned() should return true object_status has expected value' do
    tests = {
      'awaiting_approval' => false,
      'returned'          => true,
      'draft'             => false,
      'published'         => false,
    }
    tests.each do |status, exp|
      allow(item).to receive(:object_status).and_return(status)
      expect(item.is_returned).to eq(exp)
    end
  end

  describe 'is_approvable()' do
    it 'item not awaiting approval: should always return false' do
      allow(item).to receive(:is_awaiting_approval).and_return(false)
      expect(item).not_to receive('validate!')
      expect(item.is_approvable).to eq(false)
    end

    it 'item not awaiting approval: should return value of validate!' do
      allow(item).to receive(:is_awaiting_approval).and_return(true)
      [true, false].each do |exp|
        allow(item).to receive('validate!').and_return(exp)
        expect(item.is_approvable).to eq(exp)
      end
    end
  end

  it 'is_disapprovable() should return the value of is_awaiting_approval()' do
    [true, false].each do |exp|
      allow(item).to receive(:is_awaiting_approval).and_return(exp)
      expect(item.is_disapprovable).to eq(exp)
    end
  end

  describe 'is_resubmittable()' do
    it 'item not returned: should always return false' do
      allow(item).to receive(:is_returned).and_return(false)
      expect(item).not_to receive('validate!')
      expect(item.is_resubmittable).to eq(false)
    end

    it 'item not returned: should return value of validate!' do
      allow(item).to receive(:is_returned).and_return(true)
      [true, false].each do |exp|
        allow(item).to receive('validate!').and_return(exp)
        expect(item.is_resubmittable).to eq(exp)
      end
    end
  end

  it 'is_destroyable() should return the negative of is_published' do
    allow(item).to receive(:is_published).and_return(false)
    expect(item.is_destroyable).to eq(true)
    allow(item).to receive(:is_published).and_return(true)
    expect(item.is_destroyable).to eq(false)
  end

  describe 'is_publishable()' do
    it 'invalid object: should always return false' do
      # If the item were valid, this setup would cause the method to return true.
      allow(item).to receive(:requires_human_approval).and_return('no')
      allow(item).to receive(:is_draft).and_return(true)
      # But it's not valid, so we should get false.
      allow(item).to receive('validate!').and_return(false)
      expect(item.is_publishable).to eq(false)
    end

    it 'valid object: requires approval: should return value of is_awaiting_approval()' do
      allow(item).to receive('validate!').and_return(true)
      allow(item).to receive(:requires_human_approval).and_return('yes')
      [true, false, true, false].each do |exp|
        allow(item).to receive(:is_awaiting_approval).and_return(exp)
        expect(item.is_publishable).to eq(exp)
      end
    end

    it 'valid object: does not require approval: should return value of is_draft()' do
      allow(item).to receive('validate!').and_return(true)
      allow(item).to receive(:requires_human_approval).and_return('no')
      [true, false, true, false].each do |exp|
        allow(item).to receive(:is_draft).and_return(exp)
        expect(item.is_publishable).to eq(exp)
      end
    end
  end

  describe 'is_publishable_directly()' do
    it 'invalid object: should always return false' do
      # If the item were valid, this setup would cause the method to return true.
      allow(item).to receive(:requires_human_approval).and_return('no')
      allow(item).to receive(:is_draft).and_return(true)
      # But it's not valid, so we should get false.
      allow(item).to receive('validate!').and_return(false)
      expect(item.is_publishable_directly).to eq(false)
    end

    it 'valid object: requires approval: should always return false regardless of is_awaiting_approval status' do
      allow(item).to receive('validate!').and_return(true)
      allow(item).to receive(:requires_human_approval).and_return('yes')
      [true, false, true, false].each do |exp|
        allow(item).to receive(:is_awaiting_approval).and_return(exp)
        expect(item.is_publishable_directly).to eq(false)
      end
    end

    it 'valid object: does not require approval: should return value of is_draft()' do
      allow(item).to receive('validate!').and_return(true)
      allow(item).to receive(:requires_human_approval).and_return('no')
      [true, false, true, false].each do |exp|
        allow(item).to receive(:is_draft).and_return(exp)
        expect(item.is_publishable_directly).to eq(exp)
      end
    end
  end

  describe 'is_assemblable()' do
    it 'unpublished item: should always return false' do
      allow(item).to receive(:is_published).and_return(false)
      expect(item).not_to receive('validate!')
      expect(item.is_assemblable).to eq(false)
    end

    it 'is assemblable if it validates' do
      allow(item).to receive(:is_published).and_return(true)
      allow(item).to receive('validate!').and_return(true)
      expect(item.is_assemblable).to eq(true)
    end

    it 'is not assemblable if it does not validate' do
      allow(item).to receive(:is_published).and_return(true)
      allow(item).to receive('validate!').and_return(false)
      expect(item.is_assemblable).to eq(false)
    end
  end

  describe 'publish_directly()' do
    it 'item is not publishable: should raise exception' do
      allow(item).to receive(:is_publishable).and_return(false)
      expect { item.publish_directly }.to raise_exception(@cannot_do_regex)
    end

    it 'item is publishable: should call the expected methods' do
      allow(item).to receive(:is_publishable).and_return(true)
      expect(item).to receive(:complete_workflow_step).with('submit')
      expect(item).to receive(:do_publish)
      item.publish_directly
    end
  end

  describe '#do_publish' do
    subject(:publish) { item.do_publish }

    before do
      allow(item).to receive(:title).and_return(title)
      allow(item).to receive(:close_version)
      allow(item).to receive(:complete_workflow_step).with('approve')
      allow(item).to receive(:start_common_assembly)
    end

    let(:title) do
      'Examination of four early exhibitions of Giant Sequoia: ' \
      'the Snediker & Stegman ("The Mammoth Tree"; ' \
      'later to be known as "The Forest King") exhibit in Stockton, ' \
      'California (October 12-25, 1870) and the Jellerson & Ricker Big Tree ' \
      'exhibits 1870-1871 (New York, Boston, etc.)'
    end

    it 'call expected methods and set labels, status, and events' do
      publish

      expect(item).not_to have_received(:close_version)

      expect(item.label).to eq 'Examination of four early exhibitions of Giant ' \
        'Sequoia: the Snediker & Stegman ("The Mammoth Tree"; later to be ' \
        'known as "The Forest King") exhibit in Stockton, California ' \
        '(October 12-25, 1870) and the Jellerson & Ricker Big Tree exhibits ' \
        '1870-1871...'
      expect(item.submitted_for_publish_time).not_to be_blank
      expect(item.initial_submitted_for_publish_time).not_to be_blank
      expect(item.object_status).to eq('published')
      expect(item.get_hydrus_events.first.text).to match(/\AItem published: v\d/)
      allow(item).to receive(:valid?).and_return(true)
    end

    context 'when the object is not an initial version' do
      before do
        allow(item).to receive(:is_initial_version).and_return(false)
      end

      it 'closes the version' do
        publish
        expect(item).to have_received(:close_version)
      end
    end
  end

  describe 'submit_for_approval()' do
    it 'item is not submittable: should raise exception' do
      allow(item).to receive(:is_submittable_for_approval).and_return(false)
      expect { item.submit_for_approval }.to raise_exception(@cannot_do_regex)
    end

    it 'item is submittable: should set status and call expected methods' do
      allow(item).to receive(:is_submittable_for_approval).and_return(true)
      expect(item).to receive(:complete_workflow_step).with('submit')
      expect(item.submit_for_approval_time).to be_blank
      expect(item.object_status).not_to eq('awaiting_approval')
      item.submit_for_approval
      expect(item.submit_for_approval_time).not_to be_blank
      expect(item.object_status).to eq('awaiting_approval')
    end
  end

  describe 'approve()' do
    it 'item is not approvable: should raise exception' do
      allow(item).to receive(:is_approvable).and_return(false)
      expect { item.approve }.to raise_exception(@cannot_do_regex)
    end

    it 'item is approvable: should remove disapproval_reason and call expected methods' do
      allow(item).to receive(:is_approvable).and_return(true)
      expect(item).to receive(:do_publish)
      item.disapproval_reason = 'some reason'
      item.approve
      expect(item.disapproval_reason).to eq(nil)
    end
  end

  describe 'disapprove()' do
    it 'item is not disapprovable: should raise exception' do
      reason = 'some reason'
      allow(item).to receive(:is_disapprovable).and_return(false)
      expect { item.disapprove(reason) }.to raise_exception(@cannot_do_regex)
    end

    it 'item is disapprovable: should set disapproval_reason and object status and call expected methods' do
      reason = 'some reason'
      allow(item).to receive(:is_disapprovable).and_return(true)
      expect(item).to receive(:send_object_returned_email_notification)
      expect(item.disapproval_reason).to eq(nil)
      expect(item.object_status).not_to eq('returned')
      item.disapprove(reason)
      expect(item.disapproval_reason).to eq(reason)
      expect(item.object_status).to eq('returned')
    end
  end

  describe 'resubmit()' do
    it 'item is not resubmittable: should raise exception' do
      allow(item).to receive(:is_resubmittable).and_return(false)
      expect { item.resubmit }.to raise_exception(@cannot_do_regex)
    end

    it 'item is resubmittable: should remove disapproval_reason, set object status, and call expected methods' do
      allow(item).to receive(:is_resubmittable).and_return(true)
      item.disapproval_reason = 'some reason'
      expect(item.object_status).not_to eq('awaiting_approval')
      item.resubmit
      expect(item.disapproval_reason).to eq(nil)
      expect(item.object_status).to eq('awaiting_approval')
    end
  end

  describe '#open_new_version' do
    # More significant testing is done at the integration level.
    context 'when the item has not been accessioned' do
      before do
        allow(item).to receive(:version_openable?).and_return(false)
      end

      it 'raises an exception' do
        expect { item.open_new_version }.to raise_exception(@cannot_do_regex)
      end
    end

    context 'when it has been accessioned' do
      let(:description) { 'Best version ever described!' }
      let(:object_client) { instance_double(Dor::Services::Client::Object) }
      let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }

      before do
        item.submitted_for_publish_time = HyTime.now_datetime
        item.visibility = 'stanford'
        allow(item).to receive(:version_openable?).and_return(true)
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
        allow(object_client).to receive(:version).and_return(version_client)
        allow(item).to receive(:uncomplete_workflow_steps)
      end

      it 'calls the client and sets prior_visibility to the old visibility value' do
        expect(item).to receive(:start_hydrus_wf)
        item.open_new_version(description: description)
        expect(version_client).to have_received(:open).with(assume_accessioned: true,
                                                            significance: Hydrus::Item::DEFAULT_VERSION_SIGNIFICANCE,
                                                            description: description)
        expect(item.prior_visibility).to eq 'stanford'
      end
    end
  end

  describe 'close_version()' do
    context 'when item is initial version' do
      it 'should raise exception' do
        allow(item).to receive(:is_initial_version).and_return(true)
        expect { item.close_version }.to raise_exception(@cannot_do_regex)
      end
    end
    context 'when item is not initial version' do
      let(:object_client) { instance_double(Dor::Services::Client::Object) }

      let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }

      before do
        allow(item).to receive(:is_initial_version).and_return(false)
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
        allow(object_client).to receive(:version).and_return(version_client)
      end

      it 'calls the client and sets prior_visibility to the old visibility value' do
        item.close_version
        expect(version_client).to have_received(:close).with(version_num: '1', start_accession: false)
      end
    end
  end

  it 'should indicate no files have been uploaded yet' do
    expect(item.files_uploaded?).to eq(false)
  end

  it 'should indicate that release settings have not been reviewed yet' do
    expect(item.reviewed_release_settings?).to eq(false)
    item.reviewed_release_settings = 'true'
    item.revalidate
    expect(item.reviewed_release_settings?).to eq(true)
  end

  it 'should indicate that terms of deposit have not been accepted yet' do
    expect(item.terms_of_deposit_accepted?).to eq(false)
  end

  it 'should indicate if we do not require terms acceptance if user already accepted terms' do
    allow(item).to receive(:accepted_terms_of_deposit).and_return(true)
    expect(item.requires_terms_acceptance('archivist1')).to be false
  end

  it 'should indicate if we do require terms acceptance if user has never accepted terms on another item in the same collection' do
    @coll = Hydrus::Collection.new
    allow(@coll).to receive(:users_accepted_terms_of_deposit).and_return({ 'archivist3' => '10-12-2008 00:00:00', 'archivist4' => '10-12-2009 00:00:05' })
    allow(item).to receive(:accepted_terms_of_deposit).and_return(false)
    allow(item).to receive(:collection).and_return(@coll)
    expect(item.requires_terms_acceptance('archivist1')).to be true
  end

  it 'should indicate if we do require terms acceptance if user already accepted terms on another item in the same collection, but it was more than 1 year ago' do
    @coll = Hydrus::Collection.new
    allow(@coll).to receive(:users_accepted_terms_of_deposit).and_return({ 'archivist1' => '10-12-2008 00:00:00', 'archivist2' => '10-12-2009 00:00:05' })
    allow(item).to receive(:accepted_terms_of_deposit).and_return(false)
    allow(item).to receive(:collection).and_return(@coll)
    expect(item.requires_terms_acceptance('archivist1')).to be true
  end

  it 'should indicate if we do not require terms acceptance if user already accepted terms on another item in the same collection, and it was less than 1 year ago' do
    @coll = Hydrus::Collection.new
    allow(@coll).to receive(:users_accepted_terms_of_deposit).and_return({ 'archivist1' => Time.now.in_time_zone - 364.days, 'archivist2' => '10-12-2009 00:00:05' })
    allow(item).to receive(:accepted_terms_of_deposit).and_return(false)
    allow(item).to receive(:collection).and_return(@coll)
    expect(item.requires_terms_acceptance('archivist1')).to be false
  end

  it 'should accept the terms of deposit for a user' do
    @coll = Hydrus::Collection.new
    allow(Hydrus::Authorizable).to receive(:can_edit_item).and_return(true)
    allow(@coll).to receive(:accept_terms_of_deposit)
    allow(item).to receive(:collection).and_return(@coll)
    expect(item.terms_of_deposit_accepted?).to eq(false)
    expect(item.accepted_terms_of_deposit).not_to eq('true')
    item.accept_terms_of_deposit('archivist1')
    item.revalidate
    expect(item.accepted_terms_of_deposit).to eq('true')
    expect(item.terms_of_deposit_accepted?).to eq(true)
  end

  describe 'embargo_date_is_well_formed()' do
    it 'should be driven by @embargo_date_was_malformed instance variable' do
      k = :embargo_date
      [true, false].each do |exp|
        expect(item.errors.messages.keys.include?(k)).to eq(false)
        item.instance_variable_set('@embargo_date_was_malformed', exp)
        item.embargo_date_is_well_formed
        expect(item.errors.messages.keys.include?(k)).to eq(exp)
        item.errors.clear
      end
    end
  end

  it 'requires_human_approval() if the collection does' do
    allow(item).to receive_message_chain(:collection, :requires_human_approval).and_return('yes')
    expect(item.requires_human_approval).to eq('yes')
  end

  it 'does not requires_human_approval() if the collection does not' do
    allow(item).to receive_message_chain(:collection, :requires_human_approval).and_return('no')
    expect(item.requires_human_approval).to eq('no')
  end

  describe 'version getters and setters' do
    before(:each) do
      vs = [
        '<version tag="1.0.0" versionId="1"><description>Blah 1.0.0</description></version>',
        '<version tag="1.0.1" versionId="2"><description>Blah 1.0.1</description></version>',
        '<version tag="2.0.0" versionId="3"><description>Blah 2.0.0</description></version>',
        '<version tag="2.1.0" versionId="4"><description>Blah 2.1.0</description></version>',
        '<version tag="3.0.0" versionId="5"><description>Blah 3.0.0</description></version>',
        '<version tag="3.0.1" versionId="6"><description>Blah 3.0.1</description></version>',
      ]
      @stub_vm = lambda { |v|
        tags = %w(1.0.0 1.0.1 2.0.0 2.1.0 3.0.0 3.0.1)
        n = tags.find_index(v)
        xml = [
          '<?xml version="1.0"?>',
          '<versionMetadata objectId="druid:bb123bb1234">',
          vs[0..n],
          '</versionMetadata>',
        ]
        vm = Dor::VersionMetadataDS.from_xml(xml.flatten.join)
        allow(vm).to receive(:pid).and_return('druid:bb123bb1234')
        allow(item).to receive(:versionMetadata).and_return(vm)
        item.datastreams['versionMetadata'] = vm
      }
    end

    it 'basic getters should return expected attributes of the current version' do
      @stub_vm.call('1.0.0')
      expect(item.version_id).to eq('1')
      expect(item.version_tag).to eq('v1.0.0')
      expect(item.version_description).to eq('Blah 1.0.0')
      @stub_vm.call('2.1.0')
      expect(item.version_id).to eq('4')
      expect(item.version_tag).to eq('v2.1.0')
      expect(item.version_description).to eq('Blah 2.1.0')
    end

    it 'is_initial_version() should return true only for the first version' do
      @stub_vm.call('1.0.0')
      expect(item.is_initial_version).to eq(true)
      @stub_vm.call('1.0.1')
      expect(item.is_initial_version).to eq(true)
      @stub_vm.call('1.0.1')
      expect(item.is_initial_version(absolute: true)).to eq(false)
      @stub_vm.call('2.0.0')
      expect(item.is_initial_version).to eq(false)
      @stub_vm.call('2.1.0')
      expect(item.is_initial_version).to eq(false)
    end

    it 'version_significance() should return :major, :minor, or :admin' do
      tests = {
        '1.0.0' => :major,
        '2.0.0' => :major,
        '2.1.0' => :minor,
        '3.0.0' => :major,
        '3.0.1' => :admin,
      }
      tests.each do |v, exp|
        @stub_vm.call(v)
        expect(item.version_significance).to eq(exp)
      end
    end

    it 'version_significance=() should modify the version tag as expected' do
      @stub_vm.call('2.1.0')
      tests = {
        'major' => 'v3.0.0',
        'admin' => 'v2.0.1',
        'minor' => 'v2.1.0',
      }
      tests.each do |sig, exp|
        item.version_significance = sig
        expect(item.version_tag).to eq(exp)
      end
    end

    it 'version_description=() modifies the description' do
      @stub_vm.call('2.1.0')
      expect(item.version_description).to eq('Blah 2.1.0')
      exp = 'blah blah blah!!'
      item.version_description = exp
      expect(item.version_description).to eq(exp)
    end
  end
end
