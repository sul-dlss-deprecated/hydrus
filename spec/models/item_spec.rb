require 'spec_helper'

describe Hydrus::Item do
  
  before(:each) do
    @hi      = Hydrus::Item.new
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

  it "publishing an object should update identityMetadata title" do
    # TODO: waiting until Item.publish refactor
    next

    itm = Hydrus::Item.new(:pid=>'druid:tt000tt0001')
    # Before publishing.
    itm.identityMetadata.objectLabel.should == []
    # After publishing.
    t           = 'FOOBAR'
    itm.title   = t
    itm.publish = 'true'
    itm.identityMetadata.objectLabel.should == [t]
  end
  
  it "new items should be invalid if no files have been added yet" do
    item      = Hydrus::Item.new(:pid=>'druid:tt000tt0001')
    item.publish="true"
    item.valid?.should == false
    item.errors.messages[:collection].should_not be_nil
    item.errors.messages[:title].should_not be_nil
    item.errors.messages[:files].should_not be_nil    
    item.errors.messages[:terms_of_deposit].should_not be_nil    
    item.errors.messages[:abstract].should_not be_nil    
    item.add_to_collection('druid:oo000oo0003') # now associate with an open collection and check if that message goes away
    item.valid?.should == false
    item.errors.messages[:collection].should be_nil
  end
  
  it "existing item should be invalid if required fields are missing (and publish/terms of deposit was selected)" do
    @item=Hydrus::Item.find('druid:oo000oo0001')
    @item.should be_valid  # should start out as invalid
    @item.publish = "true"
    @item.terms_of_deposit = "true"
    @item.title=''
    @item.should_not be_valid # invalid!
    @item.title='ok'
    @item.should be_valid  # valid!
    @item.abstract=''  
    @item.should_not be_valid  # invalid!
    @item.abstract='ok'  
    @item.should be_valid  # valid!
    # @item.actors << Hydrus::Actor.new
    # @item.should_not be_valid  # invalid!
  end
  
  it "should invalidate any item when terms of deposit hasn't been selected" do
    @item=Hydrus::Item.find('druid:oo000oo0001')
    @item.should be_valid  # should start out as valid
    @item.publish = "true"
    @item.should_not be_valid
  end
  it "should not try to validate required fields when publish was not pressed and terms of deposit was not selected" do
    @item=Hydrus::Item.find('druid:oo000oo0001')
    @item.should be_valid  # should start out as valid
    @item.title = ""
    @item.should be_valid
    @item.abstract = ""
    @item.should be_valid
    # @item.actors << Hydrus::Actor.new
    # @item.should be_valid
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
      describe "world" do
        describe "immediate embargo" do
          subject {Hydrus::Item.new}
          before(:each) do
            subject.embargo = "immediate"
          end
          it "should set the read access to world in rightsMetadata" do
            subject.visibility = "world"
            subject.rightsMetadata.read_access.machine.world.should_not be_blank
            subject.visibility.should == ["world"]
          end
          it "should set the remove any stanford groups" do
            subject.visibility = "stanford"
            subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_true
            subject.visibility = "world"
            subject.rightsMetadata.read_access.machine.group.include?("stanford").should_not be_true
          end
          it "should get a blank releaseAccess node from embargoMD" do
            subject.visibility = "world"
            subject.embargoMetadata.ng_xml.to_s.should match(/<releaseAccess\/>/)
          end
        end
        describe "future embargo" do
          subject {Hydrus::Item.new}
          before(:each) do
            subject.embargo = "future"
            subject.embargo_date = (Date.today + 2.years).strftime("%m/%d/%Y")
          end
          it "should remove any groups from the rightsMetadata read block" do
            subject.rightsMetadata.read_access.machine.group = "stanford"
            subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_true
            subject.visibility = "world"
            subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_false
          end
          it "should add the world releasable XML to the embargoMetadata" do
            subject.visibility = "world"
            subject.embargoMetadata.ng_xml.at_xpath('//access[@type="read"]/machine/world').should_not be_nil
          end
          it "should set the release date properly" do
            subject.visibility = "world"
            subject.embargoMetadata.release_date.should == (Date.today + 2.years).beginning_of_day.utc.xmlschema
          end
        end
      end
      describe "stanford only" do
        subject {Hydrus::Item.new}
        it "should remove any world read node from rightsMD" do
          subject.embargo = "immediate"
          subject.rightsMetadata.read_access.machine.world = ""
          subject.rightsMetadata.read_access.machine.world.should == [""]
          subject.visibility = "stanford"
          subject.rightsMetadata.read_access.machine.world.should == []
          subject.rightsMetadata.read_access.machine.group.include?("stanford").should be_true
        end
        describe "immediate embargo" do
          before(:each) do
            subject.embargo = "immediate"
          end
          it "should remove the embargo release date in rightsMD" do
            subject.visibility = "stanford"
            subject.rightsMetadata.read_access.machine.embargo_release_date.first.should be_blank
          end
          it "should set the releaseAccess node to an empty node in the embargoMD" do
            subject.visibility = "stanford"
            subject.embargoMetadata.ng_xml.to_s.should match(/<releaseAccess\/>/)
          end
        end
        describe "future embargo" do
          before(:each) do
            subject.embargo = "future"
            subject.embargo_date = (Date.today + 2.years).strftime("%m/%d/%Y")
          end
          it "should set the stanford release XML in the embargoDS" do
            subject.visibility = "stanford"
            subject.embargoMetadata.ng_xml.at_xpath('//access[@type="read"]/machine/group[text()="stanford"]').should_not be_nil
          end
          it "should set the embargo date properly in the embargoDS" do
            subject.visibility = "stanford"
            subject.embargoMetadata.release_date.should == (Date.today + 2.years).beginning_of_day.utc.xmlschema
          end
        end
        
        it "should remove the stanford group when set to world/everyone and should remove the world group when set to stanford" do
          subject.rightsMetadata.read_access.machine.world.should == []
          subject.rightsMetadata.read_access.machine.group.include?("stanford").should_not be_true
          subject.visibility = "stanford"
          subject.rightsMetadata.read_access.machine.world.should == []
          subject.embargo = "immediate"
          subject.visibility = "world"
          subject.visibility.should == ["world"]
          subject.rightsMetadata.read_access.machine.world.should_not be_blank
          subject.rightsMetadata.read_access.machine.group.include?("stanford").should_not be_true
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
end
