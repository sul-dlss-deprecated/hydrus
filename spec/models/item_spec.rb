require 'spec_helper'

describe Hydrus::Item do
  
  before(:each) do
    @hi      = Hydrus::Item.new
    @workflow_xml = <<-END
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workflows objectId="druid:oo000oo0001">
        <workflow repository="dor" objectId="druid:oo000oo0001" id="sdrDepositWF">
          <process datetime="1234" name="start-deposit"/>
          <process datetime="9999" name="submit"/>
          <process datetime="1234" name="approve"/>
          <process datetime="1234" name="start-assembly"/>
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
  
  describe "class methods" do
    it "should provide an array of roles" do
      Hydrus::Item.roles.should be_a Array
    end
  end
end
