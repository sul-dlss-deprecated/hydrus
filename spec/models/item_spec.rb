require 'spec_helper'

describe Hydrus::Item do
  
  before(:each) do
    @hi = Hydrus::Item.new
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
  
  it "submit_time() should return the expect value from the workflow XML" do
    mock_wf = double('fake_workflows', :ng_xml => @workflow_xml)
    @hi.stub(:workflows).and_return(mock_wf)
    @hi.submit_time.should == "9999"
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

  describe "#actors" do
    subject { Hydrus::Item.new }
    let(:descMetadata_xml) { <<-eos
     <mods xmlns="http://www.loc.gov/mods/v3">
          <name>
              <namePart>Angus</namePart>
              <role>
                <roleTerm>guitar</roleTerm>
              </role>
          </name>
          <name>
              <namePart>John</namePart>
              <role>
                <roleTerm>bass</roleTerm>
              </role>
          </name>
     </mods>
     eos
    }
    let(:descMetadata) { Hydrus::DescMetadataDS.from_xml(descMetadata_xml) }
    
    before(:each) do
      subject.stub(:descMetadata) { descMetadata }
    end

    it "should have the right number of items" do
      subject.actors.length.should == 2
      subject.actors.all? { |x| x.should be_a_kind_of(Hydrus::Actor) }
    end

    it "should have array-like accessors" do
      actor = subject.actors.first
      actor.name.should == "Angus"
      actor.role.should == "guitar"
    end

  end # describe #actors

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
  
  describe "roleMetadata in the item" do
    subject { Hydrus::Item.find('druid:oo000oo0001') }
    it "should have a roleMetadata datastream" do
      subject.roleMetadata.should be_an_instance_of(Hydrus::RoleMetadataDS)
      subject.item_depositor_id.should == 'cardinal'
      subject.item_depositor_name.should == 'Mascot, Stanford'
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
      @hi.keywords = { 0 => 'foo', 1 => 'bar', 2 => 'quux' }
      @dsdoc.ng_xml.should be_equivalent_to <<-EOF
        #{@mods_start}
          <subject><topic>foo</topic></subject>
          <subject><topic>bar</topic></subject>
          <subject><topic>quux</topic></subject>
        </mods>
      EOF
    end

  end
  
  
  describe "item level APO information" do
    describe "visibility" do
      subject {Hydrus::Item.new}
      describe "immediate" do
        it "should remove the releaseAccess node from embargoMD" do
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "world"
          subject.embargoMetadata.ng_xml.to_s.should match(/<releaseAccess>/)
          subject.embargo = "immediate"
          subject.visibility = "world"
          subject.embargoMetadata.ng_xml.to_s.should match(/<releaseAccess\/>/)
        end
        it "should remove the embargo date from both the rightsMD and embargoMD" do
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "world"
          subject.embargoMetadata.ng_xml.to_s.should match(/<releaseDate>#{(Date.today + 2.days).beginning_of_day.utc.xmlschema}<\/releaseDate>/)
          subject.rightsMetadata.ng_xml.to_s.should match(/<embargoReleaseDate>#{(Date.today + 2.days).to_s}<\/embargoReleaseDate>/)
          subject.embargo = "immediate"
          subject.visibility = "world"
          subject.embargoMetadata.ng_xml.to_s.should_not match(/<releaseDate/)
          subject.rightsMetadata.ng_xml.to_s.should_not match(/<embargoReleaseDate/)
        end
        it "should set the current rightsMD to world readable for world" do
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "stanford"
          subject.embargoMetadata.ng_xml.to_s.should match(/<group>stanford<\/group>/)
          subject.rightsMetadata.read_access.machine.world.should == []
          subject.embargo = "immediate"
          subject.visibility = "world"
          subject.embargoMetadata.ng_xml.to_s.should_not match(/<group>stanford<\/group>/)
          subject.embargoMetadata.ng_xml.to_s.should match(/<releaseAccess\/>/)
          subject.rightsMetadata.read_access.machine.world.should == [""]
        end
        it "should set the given group in rightsMD and remove world readability for groups being set" do
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "stanford"
          subject.embargoMetadata.ng_xml.to_s.should match(/<world\/>/)
          subject.embargo = "immediate"
          subject.visibility = "stanford"
          subject.embargoMetadata.ng_xml.to_s.should_not match(/<world\/>/)
          subject.embargoMetadata.ng_xml.to_s.should match(/<releaseAccess\/>/)
          subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_true
        end
      end
      
      describe "future" do
        it "should remove the world read access from rightsMD" do
          subject.embargo = "immediate"
          subject.visibility = "world"
          subject.rightsMetadata.ng_xml.to_s.should match(/<world\/>/)
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "world"
          subject.rightsMetadata.read_access.machine.world.should == []
          subject.embargoMetadata.ng_xml.to_s.should match(/<world\/>/)
        end
        it "should remove groups from the read access of the rightsMD" do
          subject.embargo = "immediate"
          subject.visibility = "stanford"
          subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_true
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "stanford"
          subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_false
          subject.embargoMetadata.ng_xml.to_s.should match(/<group>stanford<\/group>/)
        end
        it "should set the current embargoMD to world readable for world" do
          subject.embargo = "immediate"
          subject.visibility = "stanford"
          subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_true
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "world"
          subject.embargoMetadata.ng_xml.to_s.should match(/<releaseAccess>/)
          subject.embargoMetadata.ng_xml.at_xpath("//access[@type='read']/machine/world").should_not be_nil
          subject.rightsMetadata.ng_xml.to_s.should_not match(/<group>stanford<\/group>/)
        end
        it "should set the given group in emargoMD and remove world readability for groups being set" do
          subject.embargo = "immediate"
          subject.visibility = "world"
          subject.rightsMetadata.read_access.machine.world.should == [""]
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "stanford"
          subject.rightsMetadata.read_access.machine.world.should == []
          subject.embargoMetadata.ng_xml.to_s.should match(/<releaseAccess>/)
          subject.embargoMetadata.ng_xml.at_xpath("//access[@type='read']/machine/group[text()='stanford']").should_not be_nil
          subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_false
        end
        it "should set the embargo date in the rights and embargo datastreams" do
          subject.embargo = "future"
          subject.embargo_date = (Date.today + 2.days).strftime("%m/%d/%Y")
          subject.visibility = "stanford"
          subject.embargoMetadata.release_date.should == (Date.today + 2.days).beginning_of_day.utc.xmlschema
          subject.rightsMetadata.read_access.machine.embargo_release_date.first.should == (Date.today + 2.days).to_s
        end
      end
    end

    describe "embargo" do
      subject {Hydrus::Item.new}
      it "should store the embargo_release_date element in the XML properly" do
        subject.rightsMetadata.read_access.machine.embargo_release_date.should == []
        subject.embargo_date= "8/1/2012"
        subject.rightsMetadata.read_access.machine.embargo_release_date.should == ["2012-08-01"]
        subject.rightsMetadata.ng_xml.to_s.should match(/embargoReleaseDate/)
      end
      it "should remove the embargo release date if the immediate radio button is selected (embargo= 'immediate')" do
        subject.rightsMetadata.read_access.machine.embargo_release_date.should == []
        subject.embargo_date= "8/1/2012"
        subject.rightsMetadata.read_access.machine.embargo_release_date.should == ["2012-08-01"]
        subject.embargo= 'immediate'
        subject.visibility= "world"
        subject.rightsMetadata.read_access.machine.embargo_release_date.should == []
      end
      describe "date ranges" do
        it "should return today's date if there is no completed submit time in the workflowDataStream" do
          subject.beginning_of_embargo_range.should == Date.today.strftime("%m/%d/%Y")
        end
        it "should return the submit time if one is available" do
          subject.stub(:submit_time).and_return(Date.strptime("08/01/2012", "%m/%d/%Y").to_s)
          subject.beginning_of_embargo_range.should == "08/01/2012"
        end

        it "should get the end date range properly based on the collection's APO" do
          subject.stub(:beginning_of_embargo_range).and_return("08/01/2012")
          subject.stub_chain([:collection, :first, :apo, :embargo]).and_return("6 months")
          subject.end_of_embargo_range.should == "02/01/2013"
          subject.stub_chain([:collection, :first, :apo, :embargo]).and_return("1 year")
          subject.end_of_embargo_range.should == "08/01/2013"
          subject.stub_chain([:collection, :first, :apo, :embargo]).and_return("5 years")
          subject.end_of_embargo_range.should == "08/01/2017"
        end
      end
    end
    
    describe "license" do
      subject {Hydrus::Item.new}
      it "should set the human readable version properly" do
        subject.rightsMetadata.use.human.first.should be_blank
        subject.license = "cc-by-nc"
        subject.rightsMetadata.use.human.first.should == "CC BY-NC Attribution-NonCommercial"
      end
      it "should set the type attribute properly depending on the license applied" do
         subject.rightsMetadata.use.human.first.should be_blank
         subject.license = "cc-by-nc"
         subject.rightsMetadata.ng_xml.to_s.should match(/type=\"creativeCommons\"/)
         subject.license = "odc-odbl"
         subject.rightsMetadata.ng_xml.to_s.should_not match(/type=\"creativeCommons\"/)
         subject.rightsMetadata.ng_xml.to_s.should match(/type=\"openDataCommons\"/)
      end
    end  
  end
    
  describe "class methods" do
    it "should provide an array of roles" do
      Hydrus::Item.roles.should be_a Array
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
      @exp = [:pid, :collection, :files, :title, :abstract, :contact, :terms_of_deposit]
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

    it "fully populated Item should be valid" do
      dru = 'druid:ll000ll0001'
      @hi.stub(:collection_is_open).and_return(true)
      @hi.stub(:accepted_terms_of_deposit).and_return(true)
      @exp.each { |e| @hi.stub(e).and_return(dru) }
      @hi.valid?.should == true
    end

  end

  describe "collection_is_open()" do

    before(:each) do
      vs = [false, false, false, true, false]
      @mock_colls = vs.map { |v| double('collection', :is_open => v) }
    end

    it "should return true if any of the collections are open" do
      @hi.stub(:collection).and_return(@mock_colls)
      @hi.collection_is_open.should == true
    end

    it "should return false if none of the collections are open" do
      @hi.stub(:collection).and_return(@mock_colls.reject { |c| c.is_open })
      @hi.collection_is_open.should == false
    end

    it "should return false if Item has no collections" do
      @hi.stub(:collection).and_return([])
      @hi.collection_is_open.should == false
    end

  end

end
