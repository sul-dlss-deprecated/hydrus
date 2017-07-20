require 'spec_helper'

describe Hydrus::Item, :type => :model do

  before(:each) do
    @cannot_do_regex = /\ACannot perform action/
    @hi = Hydrus::Item.new
    @hc = Hydrus::Collection.new
    allow(@hi).to receive(:collection).and_return(@hc)
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
  
  describe "#files" do
    subject { Hydrus::Item.new }

    it "should retrieve ObjectFiles from the database" do
      m = double()
      expect(Hydrus::ObjectFile).to receive(:find_all_by_pid).with(subject.pid, hash_including({:order=>"weight ASC,label ASC,file ASC"})).and_return(m)
      expect(subject.files).to eq(m)
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
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
    end

    it "contributors()" do
      expect(@hi.contributors.length).to eq(3)
      @hi.contributors.all? { |c| expect(c).to be_instance_of(Hydrus::Contributor) }
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
      expect(@hi.descMetadata.ng_xml).to be_equivalent_to(new_xml)
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
        "0" => {"name"=>"AAA", "role_key"=>"corporate_author"},
        "1" => {"name"=>"BBB", "role_key"=>"personal_author"},
      }
      expect(@hi.descMetadata.ng_xml).to be_equivalent_to(exp)
    end

  end
  describe "dates" do
    before(:each) do

    end
    it 'single_date? should be true for a normal date_created' do
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated>
          2013
          </dateCreated>
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      expect(@hi.single_date?).to be_truthy
    end
    it 'should handle an older item with no date created' do
      @xml = <<-eos

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
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      expect(@hi.dates[:date_created_approximate]).to be_falsey
    end
    it 'date_range? should be true for a date range' do
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" point="start" keyDate="yes">2005-04</dateCreated> 
          <dateCreated encoding="w3cdtf" point="end">2005-05</dateCreated> 
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      expect(@hi.single_date?).to be_falsey
      expect(@hi.date_range?).to be_truthy
    end
    it 'undated? should be true for an undated item' do
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated >Undated</dateCreated>
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      expect(@hi.undated?).to be_truthy
      expect(@hi.single_date?).to be_falsey
      expect(@hi.date_range?).to be_falsey
    end
    it 'should create a dates hash with the data to populate the form' do
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" point="start" keyDate="yes" qualifier="approximate">2005-04</dateCreated> 
          <dateCreated encoding="w3cdtf" point="end">2005-05</dateCreated> 
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      hash=@hi.dates
      expect(hash[:date_range_start]).to eq(['2005-04'])
      expect(hash[:date_range_end]).to eq(['2005-05'])
      expect(hash[:date_range_start_approximate]).to be_truthy
      expect(hash[:date_range_end_approximate]).to be_falsey
    end
    it 'should create a dates hash with the data to populate the form' do
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated >Undated</dateCreated>
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      hash=@hi.dates
      expect(hash[:date_range_start]).to eq([])
      expect(hash[:date_range_end]).to eq([])
      expect(hash[:date_range_start_approximate]).to be_falsey
      expect(hash[:date_range_end_approximate]).to be_falsey
      expect(hash[:undated]).to be_truthy
    end
    it 'should create a dates hash with the data to populate the form' do
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated>2013</dateCreated>
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      hash=@hi.dates
      expect(hash[:date_created]).to eq(['2013'])
      expect(hash[:date_range_start]).to eq([])
      expect(hash[:date_range_end]).to eq([])
      expect(hash[:date_range_start_approximate]).to be_falsey
      expect(hash[:date_range_end_approximate]).to be_falsey
      expect(hash[:undated]).to be_falsey
    end
  end
  describe "date=" do
    it 'should clear out existing dates and set a single date' do
      hash={
        :date_created => ['2013'],
        :date_created_approximate => 'hi',
        :date_type => 'single'
      }
      @hi.dates = hash
      new_hash=@hi.dates
      expect(new_hash[:date_created]).to eq(['2013'])
      expect(@hi.single_date?).to be_truthy
    end
  end
  describe 'date_display' do
    it 'should render a date range with approximate dates' do 
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" point="start" keyDate="yes" qualifier="approximate">2005-04</dateCreated> 
          <dateCreated encoding="w3cdtf" point="end" qualifier="approximate">2005-05</dateCreated> 
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      expect(@hi.date_display).to eq('[ca. 2005-04 - ca. 2005-05]')
    end
    it 'should render a date range with one approximate date' do 
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" point="start" keyDate="yes" qualifier="approximate">2005-04</dateCreated> 
          <dateCreated encoding="w3cdtf" point="end">2005-05</dateCreated> 
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      expect(@hi.date_display).to eq('[ca. 2005-04] to 2005-05')
    end
    it 'should render a date range with approximate dates' do 
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated encoding="w3cdtf" keyDate="yes" qualifier="approximate">2005-04</dateCreated> 
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      expect(@hi.date_display).to eq('[ca. 2005-04]')
    end
    it 'should work with no date present' do 
      @xml = <<-eos
        <mods xmlns="http://www.loc.gov/mods/v3">
          <originInfo>
          <dateCreated></dateCreated> 
          </originInfo>
        </mods>
      eos
      allow(@hi).to receive(:descMetadata).and_return(Hydrus::DescMetadataDS.from_xml(@xml))
      expect(@hi.date_display).to eq('')
    end
    
    
  end
  describe "roleMetadata in the item", :integration=>true do
    subject { Hydrus::Item.find('druid:oo000oo0001') }
    it "should have a roleMetadata datastream" do
      expect(subject.roleMetadata).to be_an_instance_of(Hydrus::RoleMetadataDS)
      expect(subject.item_depositor_id).to eq('archivist1')
      expect(subject.item_depositor_name).to eq('Archivist, One')
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
      allow(@hi).to receive(:descMetadata).and_return(@dsdoc)
    end

    it "keywords() should return expected values" do
      expect(@hi.keywords).to eq(%w(divorce marriage))
    end

    it "keywords= should rewrite all <subject> nodes" do
      @hi.keywords = ' foo , bar , quux  '
      expect(@dsdoc.ng_xml).to be_equivalent_to <<-EOF
        #{@mods_start}
          <subject><topic>foo</topic></subject>
          <subject><topic>bar</topic></subject>
          <subject><topic>quux</topic></subject>
        </mods>
      EOF
    end

    it "keywords= should not modify descMD if the keywords are same as existing" do
      kws = %w(foo bar)
      allow(@hi).to receive(:keywords).and_return(kws)
      expect(@hi).not_to receive(:descMetadata)
      @hi.keywords = kws.join(',')
    end

  end

  describe "visibility()" do

    it "should return [] for initial visibility" do
      tests = [true, false]
      tests.each do |is_emb|
        allow(@hi).to receive(:is_embargoed).and_return(is_emb)
        expect(@hi.visibility).to eq([])
      end
    end

    it "should return ['world'] if item is world visible" do
      tests = {
        true  => :embargoMetadata,
        false => :rightsMetadata,
      }
      tests.each do |is_emb, ds|
        allow(@hi).to receive(:is_embargoed).and_return(is_emb)
        allow(@hi).to receive_message_chain(ds, :has_world_read_node).and_return(true)
        expect(@hi.visibility).to eq(['world'])
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
        allow(@hi).to receive(:is_embargoed).and_return(is_emb)
        allow(@hi).to receive_message_chain(ds, :has_world_read_node).and_return(false)
        allow(@hi).to receive_message_chain(ds, :group_read_nodes).and_return(mock_nodes)
        expect(@hi.visibility).to eq(exp_groups)
      end
    end

  end

  describe "embarg_visib=()" do

    before(:each) do
      @edate = '2012-02-28T08:00:00Z'
      # This enables the tests to run in a timezone other than Pacific.
      allow(HyTime).to receive(:datetime).with("2012-02-28", :from_localzone => true).and_return(@edate)
      # XML snippets for various <access> nodes.
      ed       = "<embargoReleaseDate>#{@edate}</embargoReleaseDate><none/>"

      twpc = "         <twentyPctVisibilityStatus/>
         <twentyPctVisibilityReleaseDate/>"

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
      rm_end   = '<use><human type="useAndReproduction"/></use>' +
                 '</rightsMetadata>'
      # Assemble expected Nokogiri XML for embargoMetadata and rightsMetadata.
      @xml = {
        :em_world   => noko_doc([em_start, em_world, twpc, em_end].join),
        :em_stanf   => noko_doc([em_start, em_stanf, twpc, em_end].join),
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
        expect(@hi.embargoMetadata).to receive(:delete) unless emb
        @hi.embarg_visib = h
        expect(@hi.rightsMetadata.ng_xml).to  be_equivalent_to(@xml[exp_rm])
        expect(@hi.embargoMetadata.ng_xml).to be_equivalent_to(@xml[exp_em]) if emb
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
        allow(@hi).to receive(:embargo_date).and_return(dt)
        expect(@hi.is_embargoed).to eq(exp)
      end
    end

    describe "embargo_date() and embargo_date=()" do

      it "getter should return value from embargoMetadata" do
        exp = 'foo release date'
        allow(@hi).to receive_message_chain(:embargoMetadata, :release_date).and_return(exp)
        expect(@hi.embargo_date).to eq(exp)
      end

      describe "setter: with valid date" do
        let(:rd_dt) { "2012-08-30T08:00:00Z" }
        before do
          # This enables the tests to run in a timezone other than Pacific.
          allow(HyTime).to receive(:datetime).with("2012-08-30", :from_localzone => true).and_return(rd_dt)
        end

        it "store date in UTC in both embargoMD and rightsMD" do
          @hi.embargo_date = '2012-08-30'
          expect(@hi.embargo_date).to eq(rd_dt)
          expect(@hi.rmd_embargo_release_date).to eq(rd_dt)
          expect(@hi.embargoMetadata.status).to eq('embargoed')
          expect(@hi.instance_variable_get('@embargo_date_was_malformed')).to eq(nil)
        end

      end

      describe "setter: with invalid date" do

        it "blank or nil: delete embargoMetadata; do not set instance var" do
          expect(@hi.embargoMetadata).to receive(:delete)
          dt = rand() < 0.5 ? '' : nil
          @hi.embargo_date = dt
          expect(@hi.rightsMetadata.ng_xml.at_xpath("//embargoReleaseDate")).to eq(nil)
          expect(@hi.instance_variable_get('@embargo_date_was_malformed')).to eq(nil)
        end

        it "malformed: do not delete embargoMetadata; set instance var" do
          expect(@hi.embargoMetadata).not_to receive(:delete)
          @hi.embargo_date = 'blah'
          expect(@hi.rightsMetadata.ng_xml.at_xpath("//embargoReleaseDate")).to eq(nil)
          expect(@hi.instance_variable_get('@embargo_date_was_malformed')).to eq(true)
        end

      end

    end

    describe "beginning_of_embargo_range()" do

      it "initial_submitted_for_publish_time missing: should return now_datetime()" do
        exp = 'foo bar'
        allow(HyTime).to receive(:now_datetime).and_return(exp)
        allow(@hi).to receive(:initial_submitted_for_publish_time).and_return(nil)
        expect(@hi.beginning_of_embargo_range).to eq(exp)
      end

      it "initial_submitted_for_publish_time present: should return it" do
        exp = 'foo bar blah'
        allow(@hi).to receive(:initial_submitted_for_publish_time).and_return(exp)
        expect(@hi.beginning_of_embargo_range).to eq(exp)
      end

    end

    describe "end_of_embargo_range()" do

      it "should get the end date range properly based on the collection's APO" do
        t = 'T00:00:00Z'
        allow(@hi).to receive(:beginning_of_embargo_range).and_return("2012-08-01#{t}")
        tests = {
          '6 months' => "2013-02-01#{t}",
          '1 year'   => "2013-08-01#{t}",
          '5 years'  => "2017-08-01#{t}",
        }
        tests.each do |emb, exp|
          allow(@hi).to receive_message_chain(:collection, :embargo_terms).and_return(emb)
          expect(@hi.end_of_embargo_range).to eq(exp)
        end
      end

    end

    describe "embargo_can_be_changed()" do

      it "Collection does not allow embargo variability: should return false" do
        expect(@hi).not_to receive(:is_initial_version)
        %w(none fixed).each do |opt|
          allow(@hc).to receive(:embargo_option).and_return(opt)
          expect(@hi.embargo_can_be_changed).to eq(false)
        end
      end

      describe "Collection allows embargo variability" do

        before(:each) do
          allow(@hc).to receive(:embargo_option).and_return('varies')
        end

        it "initial version: always true" do
          allow(@hi).to receive(:is_initial_version).and_return(true)
          expect(@hi).not_to receive(:is_embargoed)
          expect(@hi.embargo_can_be_changed).to eq(true)
        end

        it "subsequent versions: not embargoed: always false" do
          allow(@hi).to receive(:is_initial_version).and_return(false)
          allow(@hi).to receive(:is_embargoed).and_return(false)
          expect(@hi).not_to receive(:end_of_embargo_range)
          expect(@hi.embargo_can_be_changed).to eq(false)
        end

        it "subsequent versions: embargoed: true if end_of_embargo_range is in future" do
          allow(@hi).to receive(:is_initial_version).and_return(false)
          allow(@hi).to receive(:is_embargoed).and_return(true)
          tpast = HyTime.datetime(HyTime.now - 2.day)
          tfut  = HyTime.datetime(HyTime.now + 2.day)
          allow(@hi).to receive(:end_of_embargo_range).and_return(tpast)
          expect(@hi.embargo_can_be_changed).to eq(false)
          allow(@hi).to receive(:end_of_embargo_range).and_return(tfut)
          expect(@hi.embargo_can_be_changed).to eq(true)
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
      allow(@hi).to receive(:descMetadata).and_return(dmd)
    end

    it "should be able to call method on a Hydrus::Item to remove whitespace" do
      a = @hi.abstract
      t = @hi.title
      @hi.strip_whitespace_from_fields([:abstract, :title])
      expect(@hi.abstract).to eq(a.strip)
      expect(@hi.title).to eq(t.strip)
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
      allow(@hi).to receive(:should_validate).and_return(false)
      expect(@hi.valid?).to eq(false)
      expect(@hi.errors.messages.keys).to include(*@exp[0..1])
    end

    it "blank slate Item (should_validate=true) should include all errors" do
      expect(@hi.valid?).to eq(false)
      expect(@hi.errors.messages.keys).to include(*@exp)
    end

    describe "embargo_date_in_range()" do

      it "should not perform validation unless preconditions are met" do
        expect(@hi).not_to receive(:beginning_of_embargo_range)
        allow(@hi).to receive(:is_embargoed).and_return(false)
        @hi.embargo_date_in_range
      end

      it "should add a validation error when embargo_date falls outside the embargo range" do
        # Set up beginning/end of embargo range.
        b   = '2012-02-01T08:00:00Z'
        e   = '2012-03-01T08:00:00Z'
        bdt = HyTime.datetime(b)
        edt = HyTime.datetime(e)
        allow(@hi).to receive(:beginning_of_embargo_range).and_return(bdt)
        allow(@hi).to receive(:end_of_embargo_range).and_return(edt)
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
        allow(@hi).to receive(:is_embargoed).and_return(true)
        k = :embargo_date
        dts.each do |dt, is_ok|
          expect(@hi.errors).not_to have_key(k)
          allow(@hi).to receive(k).and_return(HyTime.datetime(dt))
          @hi.embargo_date_in_range
          if is_ok
            expect(@hi.errors).not_to have_key(k)
          else
            expect(@hi.errors).to have_key(k)
            expect(@hi.errors.messages[k].first).to eq(exp_msg)
          end
          @hi.errors.clear
        end
      end

    end

    it "fully populated Item should be valid" do
      dru = 'druid:ll000ll0001'
      allow(@hi).to receive(:enforce_collection_is_open).and_return(true)
      allow(@hi).to receive(:accepted_terms_of_deposit).and_return(true)
      allow(@hi).to receive(:reviewed_release_settings).and_return(true)
      @exp.each { |e| allow(@hi).to receive(e).and_return(dru) unless e==:contact }
      allow(@hi).to receive(:contact).and_return('test@test.com') # we need a valid email address
      allow(@hi).to receive(:contributors).and_return([Hydrus::Contributor.new(:name=>'Some, person')]) # need at least one non-blank contributor
      allow(@hi).to receive(:keywords).and_return(%w(aaa bbb))
      allow(@hi).to receive(:dates).and_return({:date_created => '2011'})
      allow(@hi).to receive(:date_created).and_return('2011')
      allow(@hi).to receive(:single_date?).and_return true
      allow(@hi).to receive_message_chain([:collection, :embargo_option]).and_return("varies")
      if not @hi.valid? 
        msg=@hi.errors.messages.map { |field, error|
        "#{field.to_s.humanize.capitalize} #{error.join(', ')}"
        }
        raise msg.join ', \n'
      end
      expect(@hi.valid?).to eq(true)
    end

    it "enforce_collection_is_open() should return true only if the Item is in an open Collection" do
      n  = 0
      [true, false, nil].each do |stub_val|
        c    = double('collection', :is_open => stub_val)
        exp  = not(not(stub_val))
        n   += 1 unless exp
        allow(@hi).to receive(:collection).and_return(c)
        expect(@hi.enforce_collection_is_open).to eq(exp)
        expect(@hi.errors.size).to eq(n)
      end
    end

    describe "check_version_if_license_changed()" do

      before(:each) do
        # Setup failing conditions.
        allow(@hi).to receive(:is_initial_version).and_return(false)
        allow(@hi).to receive(:license).and_return('A')
        allow(@hi).to receive(:prior_license).and_return('B')
        allow(@hi).to receive(:version_significance).and_return(:minor)
        # Lambdas to check for errors.
        @assert_no_errors = lambda { expect(@hi.errors.messages.keys).to eq([]) }
        @assert_no_errors.call
      end

      it "can produce a version error" do
        @hi.check_version_if_license_changed
        expect(@hi.errors.messages.keys).to eq([:version])
      end

      it "initial version: cannot produce a version error" do
        allow(@hi).to receive(:is_initial_version).and_return(true)
        @hi.check_version_if_license_changed
        @assert_no_errors.call
      end

      it "license was not changed: cannot produce a version error" do
        allow(@hi).to receive(:prior_license).and_return(@hi.license)
        @hi.check_version_if_license_changed
        @assert_no_errors.call
      end

      it "version is major: cannot produce a version error" do
        allow(@hi).to receive(:version_significance).and_return(:major)
        @hi.check_version_if_license_changed
        @assert_no_errors.call
      end

    end

    describe "check_visibility_not_reduced()" do

      before(:each) do
        # Setup failing conditions.
        allow(@hi).to receive(:is_initial_version).and_return(false)
        allow(@hi).to receive(:visibility).and_return(['stanford'])
        allow(@hi).to receive(:prior_visibility).and_return('world')
        # Lambdas to check for errors.
        @assert_no_errors = lambda { expect(@hi.errors.messages.keys).to eq([]) }
        @assert_no_errors.call
      end

      it "can produce a version error" do
        @hi.check_visibility_not_reduced
        expect(@hi.errors.messages.keys).to eq([:visibility])
      end

      it "initial version: cannot produce a visibility error" do
        allow(@hi).to receive(:is_initial_version).and_return(true)
        @hi.check_visibility_not_reduced
        @assert_no_errors.call
      end

      it "visibility was not changed: cannot produce a visibility error" do
        allow(@hi).to receive(:prior_visibility).and_return(@hi.visibility.first)
        @hi.check_visibility_not_reduced
        @assert_no_errors.call
      end

      it "visibility was expanded: cannot produce a visibility error" do
        allow(@hi).to receive(:visibility).and_return(['world'])
        allow(@hi).to receive(:prior_visibility).and_return('stanford')
        @hi.check_visibility_not_reduced
        @assert_no_errors.call
      end

    end

  end

  it "can exercise discovery_roles()" do
    expect(Hydrus::Item.discovery_roles).to be_instance_of(Hash)
  end

  it "can exercise tracked_fields()" do
    expect(@hi.tracked_fields).to be_an_instance_of(Hash)
  end

  describe "is_submittable_for_approval()" do

    it "if item is not a draft, should return false" do
      # Normally this would lead to a true result.
      allow(@hi).to receive(:requires_human_approval).and_return('yes')
      allow(@hi).to receive('validate!').and_return(true)
      # But since the item is not a draft, we expect false.
      allow(@hi).to receive(:object_status).and_return('returned')
      expect(@hi.is_submittable_for_approval).to eq(false)
    end

    it "if item does not require human approval, should return false" do
      # Normally this would lead to a true result.
      allow(@hi).to receive(:object_status).and_return('draft')
      allow(@hi).to receive('validate!').and_return(true)
      # But since the item does not require human approval, we expect false.
      allow(@hi).to receive(:requires_human_approval).and_return('no')
      expect(@hi.is_submittable_for_approval).to eq(false)
    end

    it "otherwise, should return the value of validate!" do
      allow(@hi).to receive(:object_status).and_return('draft')
      allow(@hi).to receive(:requires_human_approval).and_return('yes')
      [true, false, true, false].each do |exp|
        allow(@hi).to receive('validate!').and_return(exp)
        expect(@hi.is_submittable_for_approval).to eq(exp)
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
      allow(@hi).to receive(:object_status).and_return(status)
      expect(@hi.is_awaiting_approval).to eq(exp)
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
      allow(@hi).to receive(:object_status).and_return(status)
      expect(@hi.is_returned).to eq(exp)
    end
  end

  describe "is_approvable()" do

    it "item not awaiting approval: should always return false" do
      allow(@hi).to receive(:is_awaiting_approval).and_return(false)
      expect(@hi).not_to receive('validate!')
      expect(@hi.is_approvable).to eq(false)
    end

    it "item not awaiting approval: should return value of validate!" do
      allow(@hi).to receive(:is_awaiting_approval).and_return(true)
      [true, false].each do |exp|
        allow(@hi).to receive('validate!').and_return(exp)
        expect(@hi.is_approvable).to eq(exp)
      end
    end

  end

  it "is_disapprovable() should return the value of is_awaiting_approval()" do
    [true, false].each do |exp|
      allow(@hi).to receive(:is_awaiting_approval).and_return(exp)
      expect(@hi.is_disapprovable).to eq(exp)
    end
  end

  describe "is_resubmittable()" do

    it "item not returned: should always return false" do
      allow(@hi).to receive(:is_returned).and_return(false)
      expect(@hi).not_to receive('validate!')
      expect(@hi.is_resubmittable).to eq(false)
    end

    it "item not returned: should return value of validate!" do
      allow(@hi).to receive(:is_returned).and_return(true)
      [true, false].each do |exp|
        allow(@hi).to receive('validate!').and_return(exp)
        expect(@hi.is_resubmittable).to eq(exp)
      end
    end

  end

  it "is_destroyable() should return the negative of is_published" do
    allow(@hi).to receive(:is_published).and_return(false)
    expect(@hi.is_destroyable).to eq(true)
    allow(@hi).to receive(:is_published).and_return(true)
    expect(@hi.is_destroyable).to eq(false)
  end

  describe "is_publishable()" do

    it "invalid object: should always return false" do
      # If the item were valid, this setup would cause the method to return true.
      allow(@hi).to receive(:requires_human_approval).and_return('no')
      allow(@hi).to receive(:is_draft).and_return(true)
      # But it's not valid, so we should get false.
      allow(@hi).to receive('validate!').and_return(false)
      expect(@hi.is_publishable).to eq(false)
    end

    it "valid object: requires approval: should return value of is_awaiting_approval()" do
      allow(@hi).to receive('validate!').and_return(true)
      allow(@hi).to receive(:requires_human_approval).and_return('yes')
      [true, false, true, false].each do |exp|
        allow(@hi).to receive(:is_awaiting_approval).and_return(exp)
        expect(@hi.is_publishable).to eq(exp)
      end
    end

    it "valid object: does not require approval: should return value of is_draft()" do
      allow(@hi).to receive('validate!').and_return(true)
      allow(@hi).to receive(:requires_human_approval).and_return('no')
      [true, false, true, false].each do |exp|
        allow(@hi).to receive(:is_draft).and_return(exp)
        expect(@hi.is_publishable).to eq(exp)
      end
    end

  end

  describe "is_publishable_directly()" do

    it "invalid object: should always return false" do
      # If the item were valid, this setup would cause the method to return true.
      allow(@hi).to receive(:requires_human_approval).and_return('no')
      allow(@hi).to receive(:is_draft).and_return(true)
      # But it's not valid, so we should get false.
      allow(@hi).to receive('validate!').and_return(false)
      expect(@hi.is_publishable_directly).to eq(false)
    end

    it "valid object: requires approval: should always return false regardless of is_awaiting_approval status" do
      allow(@hi).to receive('validate!').and_return(true)
      allow(@hi).to receive(:requires_human_approval).and_return('yes')
      [true, false, true, false].each do |exp|
        allow(@hi).to receive(:is_awaiting_approval).and_return(exp)
        expect(@hi.is_publishable_directly).to eq(false)
      end
    end

    it "valid object: does not require approval: should return value of is_draft()" do
      allow(@hi).to receive('validate!').and_return(true)
      allow(@hi).to receive(:requires_human_approval).and_return('no')
      [true, false, true, false].each do |exp|
        allow(@hi).to receive(:is_draft).and_return(exp)
        expect(@hi.is_publishable_directly).to eq(exp)
      end
    end

  end
  
  describe "is_assemblable()" do

    it "unpublished item: should always return false" do
      allow(@hi).to receive(:is_published).and_return(false)
      expect(@hi).not_to receive('validate!')
      expect(@hi.is_assemblable).to eq(false)
    end

    it "published item: should return value of validate!" do
      allow(@hi).to receive(:is_published).and_return(true)
      [true, false].each do |exp|
        allow(@hi).to receive('validate!').and_return(exp)
        expect(@hi.is_assemblable).to eq(exp)
      end
    end

  end

  describe "publish_directly()" do

    it "item is not publishable: should raise exception" do
      allow(@hi).to receive(:is_publishable).and_return(false)
      expect { @hi.publish_directly }.to raise_exception(@cannot_do_regex)
    end

    it "item is publishable: should call the expected methods" do
      allow(@hi).to receive(:is_publishable).and_return(true)
      expect(@hi).to receive(:complete_workflow_step).with('submit')
      expect(@hi).to receive(:do_publish)
      @hi.publish_directly
    end

  end

  describe "do_publish()" do

    it "should call expected methods and set labels, status, and events" do
      # Set up object title.
      exp = 'foobar title'
      allow(@hi).to receive(:title).and_return(exp)
      # Stub method calls.
      expect(@hi).to receive(:complete_workflow_step).with('approve')
      expect(@hi).not_to receive(:close_version)
      expect(@hi).to receive(:start_common_assembly)
      # Before-assertions.
      expect(@hi.is_initial_version).to eq(true)
      expect(@hi.submitted_for_publish_time).to be_blank
      expect(@hi.initial_submitted_for_publish_time).to be_blank
      expect(@hi.get_hydrus_events.size).to eq(0)
      # Run it, and make after-assertions.
      @hi.do_publish
      expect(@hi.label).to eq(exp)
      expect(@hi.submitted_for_publish_time).not_to be_blank
      expect(@hi.initial_submitted_for_publish_time).not_to be_blank
      expect(@hi.object_status).to eq('published')
      expect(@hi.get_hydrus_events.first.text).to match(/\AItem published: v\d/)
    end

    it "should close_version() if the object is not an initial version" do
      allow(@hi).to receive(:complete_workflow_step)
      allow(@hi).to receive(:start_common_assembly)
      allow(@hi).to receive(:is_initial_version).and_return(false)
      expect(@hi).to receive(:close_version)
      @hi.do_publish
    end

  end

  describe "submit_for_approval()" do

    it "item is not submittable: should raise exception" do
      allow(@hi).to receive(:is_submittable_for_approval).and_return(false)
      expect { @hi.submit_for_approval }.to raise_exception(@cannot_do_regex)
    end

    it "item is submittable: should set status and call expected methods" do
      allow(@hi).to receive(:is_submittable_for_approval).and_return(true)
      expect(@hi).to receive(:complete_workflow_step).with('submit')
      expect(@hi.submit_for_approval_time).to be_blank
      expect(@hi.object_status).not_to eq('awaiting_approval')
      @hi.submit_for_approval
      expect(@hi.submit_for_approval_time).not_to be_blank
      expect(@hi.object_status).to eq('awaiting_approval')
    end

  end

  describe "approve()" do

    it "item is not approvable: should raise exception" do
      allow(@hi).to receive(:is_approvable).and_return(false)
      expect { @hi.approve }.to raise_exception(@cannot_do_regex)
    end

    it "item is approvable: should remove disapproval_reason and call expected methods" do
      allow(@hi).to receive(:is_approvable).and_return(true)
      expect(@hi).to receive(:do_publish)
      @hi.disapproval_reason = 'some reason'
      @hi.approve
      expect(@hi.disapproval_reason).to eq(nil)
    end

  end

  describe "disapprove()" do

    it "item is not disapprovable: should raise exception" do
      reason = 'some reason'
      allow(@hi).to receive(:is_disapprovable).and_return(false)
      expect { @hi.disapprove(reason) }.to raise_exception(@cannot_do_regex)
    end

    it "item is disapprovable: should set disapproval_reason and object status and call expected methods" do
      reason = 'some reason'
      allow(@hi).to receive(:is_disapprovable).and_return(true)
      expect(@hi).to receive(:send_object_returned_email_notification)
      expect(@hi.disapproval_reason).to eq(nil)
      expect(@hi.object_status).not_to eq('returned')
      @hi.disapprove(reason)
      expect(@hi.disapproval_reason).to eq(reason)
      expect(@hi.object_status).to eq('returned')
    end

  end

  describe "resubmit()" do

    it "item is not resubmittable: should raise exception" do
      allow(@hi).to receive(:is_resubmittable).and_return(false)
      expect { @hi.resubmit }.to raise_exception(@cannot_do_regex)
    end

    it "item is resubmittable: should remove disapproval_reason, set object status, and call expected methods" do
      allow(@hi).to receive(:is_resubmittable).and_return(true)
      @hi.disapproval_reason = 'some reason'
      expect(@hi.object_status).not_to eq('awaiting_approval')
      @hi.resubmit
      expect(@hi.disapproval_reason).to eq(nil)
      expect(@hi.object_status).to eq('awaiting_approval')
    end

  end

  describe "open_new_version()" do

    # More significant testing is done at the integration level.

    it "should raise exception if item is initial version" do
      allow(@hi).to receive(:is_accessioned).and_return(false)
      expect { @hi.open_new_version }.to raise_exception(@cannot_do_regex)
    end

  end

  describe "close_version()" do

    it "should raise exception if item is initial version" do
      allow(@hi).to receive(:is_initial_version).and_return(true)
      expect { @hi.close_version }.to raise_exception(@cannot_do_regex)
    end

  end

  it "should indicate no files have been uploaded yet" do
    expect(@hi.files_uploaded?).to eq(false)
  end

  it "should indicate that release settings have not been reviewed yet" do
    expect(@hi.reviewed_release_settings?).to eq(false)
    @hi.reviewed_release_settings="true"
    @hi.revalidate
    expect(@hi.reviewed_release_settings?).to eq(true)
  end

  it "should indicate that terms of deposit have not been accepted yet" do
    expect(@hi.terms_of_deposit_accepted?).to eq(false)
  end

  it "should indicate if we do not require terms acceptance if user already accepted terms" do
    allow(@hi).to receive(:accepted_terms_of_deposit).and_return(true)
    expect(@hi.requires_terms_acceptance('archivist1')).to be false
  end

  it "should indicate if we do require terms acceptance if user has never accepted terms on another item in the same collection" do
    @coll=Hydrus::Collection.new
    allow(@coll).to receive(:users_accepted_terms_of_deposit).and_return({'archivist3'=>'10-12-2008 00:00:00','archivist4'=>'10-12-2009 00:00:05'})
    allow(@hi).to receive(:accepted_terms_of_deposit).and_return(false)
    allow(@hi).to receive(:collection).and_return(@coll)
    expect(@hi.requires_terms_acceptance('archivist1')).to be true
  end

  it "should indicate if we do require terms acceptance if user already accepted terms on another item in the same collection, but it was more than 1 year ago" do
    @coll=Hydrus::Collection.new
    allow(@coll).to receive(:users_accepted_terms_of_deposit).and_return({'archivist1'=>'10-12-2008 00:00:00','archivist2'=>'10-12-2009 00:00:05'})
    allow(@hi).to receive(:accepted_terms_of_deposit).and_return(false)
    allow(@hi).to receive(:collection).and_return(@coll)
    expect(@hi.requires_terms_acceptance('archivist1')).to be true
  end

  it "should indicate if we do not require terms acceptance if user already accepted terms on another item in the same collection, and it was less than 1 year ago" do
    @coll=Hydrus::Collection.new
    allow(@coll).to receive(:users_accepted_terms_of_deposit).and_return({'archivist1'=>Time.now.in_time_zone - 364.days,'archivist2'=>'10-12-2009 00:00:05'})
    allow(@hi).to receive(:accepted_terms_of_deposit).and_return(false)
    allow(@hi).to receive(:collection).and_return(@coll)
    expect(@hi.requires_terms_acceptance('archivist1')).to be false
  end

  it "should accept the terms of deposit for a user" do
    @coll=Hydrus::Collection.new
    allow(Hydrus::Authorizable).to receive(:can_edit_item).and_return(true)
    allow(@coll).to receive(:accept_terms_of_deposit)
    allow(@hi).to receive(:collection).and_return(@coll)
    expect(@hi.terms_of_deposit_accepted?).to eq(false)
    expect(@hi.accepted_terms_of_deposit).not_to eq('true')
    @hi.accept_terms_of_deposit('archivist1')
    @hi.revalidate
    expect(@hi.accepted_terms_of_deposit).to eq('true')
    expect(@hi.terms_of_deposit_accepted?).to eq(true)
  end

  describe "embargo_date_is_well_formed()" do

    it "should be driven by @embargo_date_was_malformed instance variable" do
      k = :embargo_date
      [true, false].each do |exp|
        expect(@hi.errors.messages.keys.include?(k)).to eq(false)
        @hi.instance_variable_set('@embargo_date_was_malformed', exp)
        @hi.embargo_date_is_well_formed
        expect(@hi.errors.messages.keys.include?(k)).to eq(exp)
        @hi.errors.clear
      end
    end

  end

  it "requires_human_approval() should delegate to the collection" do
    ["yes", "no", "yes"].each { |exp|
      allow(@hi).to receive_message_chain(:collection, :requires_human_approval).and_return(exp)
      expect(@hi.requires_human_approval).to eq(exp)
    }
  end

  describe "version getters and setters" do

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
          '<versionMetadata objectId="druid:oo000oo0001">',
          vs[0..n],
          '</versionMetadata>',
        ]
        vm = Dor::VersionMetadataDS.from_xml(xml.flatten.join)
        allow(vm).to receive(:pid).and_return('druid:oo000oo0001')
        allow(@hi).to receive(:versionMetadata).and_return(vm)
        @hi.datastreams['versionMetadata'] = vm
      }
    end

    it "basic getters should return expected attributes of the current version" do
      @stub_vm.call('1.0.0')
      expect(@hi.version_id).to eq('1')
      expect(@hi.version_tag).to eq('v1.0.0')
      expect(@hi.version_description).to eq('Blah 1.0.0')
      @stub_vm.call('2.1.0')
      expect(@hi.version_id).to eq('4')
      expect(@hi.version_tag).to eq('v2.1.0')
      expect(@hi.version_description).to eq('Blah 2.1.0')
    end

    it "is_initial_version() should return true only for the first version" do
      @stub_vm.call('1.0.0')
      expect(@hi.is_initial_version).to eq(true)
      @stub_vm.call('1.0.1')
      expect(@hi.is_initial_version).to eq(true)
      @stub_vm.call('1.0.1')
      expect(@hi.is_initial_version(:absolute => true)).to eq(false)
      @stub_vm.call('2.0.0')
      expect(@hi.is_initial_version).to eq(false)
      @stub_vm.call('2.1.0')
      expect(@hi.is_initial_version).to eq(false)
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
        expect(@hi.version_significance).to eq(exp)
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
        expect(@hi.version_tag).to eq(exp)
      end
    end

    it "version_description=() modifies the description" do
      @stub_vm.call('2.1.0')
      expect(@hi.version_description).to eq('Blah 2.1.0')
      exp = 'blah blah blah!!'
      @hi.version_description = exp
      expect(@hi.version_description).to eq(exp)
    end

  end
end
