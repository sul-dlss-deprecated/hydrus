require 'spec_helper'

describe Hydrus::DescMetadataDS do

  before(:all) do
    sloc = "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd"
    @mods_start = <<-EOF
      <?xml version="1.0"?>
      <mods xmlns="http://www.loc.gov/mods/v3"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            version="3.3"
            xsi:schemaLocation="#{sloc}">
    EOF
  end

  context "Marshalling to and from a Fedora Datastream" do

    before(:each) do
      dsxml = <<-EOF
        #{@mods_start}
          <originInfo>
            <dateOther>Nov 7</dateIssued>
          </originInfo>
          <abstract>abstract content</abstract>
          <titleInfo>
            <title>Learn VB in 21 Days</title>
          </titleInfo>
          <name>
            <namePart>Angus</namePart>
            <role>
              <roleTerm>guitar</roleTerm>
            </role>
          </name>
          <relatedItem>
            <titleInfo>
              <title>Learn VB in 1 Day</title>
            </titleInfo>
            <identifier type="uri">http://example.com</identifier>
            <identifier type="foo">FUBB</identifier>
            <note type="preferred citation">pref_cite inner</note>
          </relatedItem>
          <subject>
            <topic>divorce</topic>
            <topic>marriage</topic>
          </subject>
          <note type="preferred citation">pref_cite outer</note>
        </mods>
      EOF
      
      @dsdoc = Hydrus::DescMetadataDS.from_xml(dsxml)
    end
    
    it "should get correct values from OM terminology" do
      tests = [
        [[:originInfo, :dateOther],          'Nov 7'],
        [:abstract,                          'abstract content'],
        [:title,                             'Learn VB in 21 Days'],
        [[:name, :namePart],                 'Angus'],
        [[:name, :role, :roleTerm],          'guitar'],
        [[:relatedItem, :titleInfo, :title], 'Learn VB in 1 Day'],
        [[:relatedItem, :identifier],        'http://example.com'],
        [[:relatedItem, :cite_related_as],   'pref_cite inner'],
        [[:subject, :topic],                 ['divorce', 'marriage']],
        [:preferred_citation,                'pref_cite outer'],
      ]
      tests.each do |terms, exp|
        terms = [terms] unless terms.class == Array
        exp   = [exp]   unless exp.class == Array
        @dsdoc.term_values(*terms).should == exp
      end
    end

  end
    
  context "Inserting new nodes" do

    it "Should be able to insert new XML nodes" do
      nm = '<name><namePart/><role><roleTerm authority="marcrelator" type="text"/></role></name>'
      ri = '<relatedItem><titleInfo><title/></titleInfo><identifier type="uri"/></relatedItem>'
      @exp_xml = noko_doc([@mods_start, nm, nm, nm, ri, ri, '</mods>'].join '')
      @dsdoc   = Hydrus::DescMetadataDS.from_xml("#{@mods_start}</mods>")

      @dsdoc.insert_person
      @dsdoc.insert_new_node(:name)
      @dsdoc.insert_new_node(:name)
      @dsdoc.insert_related_item
      @dsdoc.insert_new_node(:relatedItem)
      @dsdoc.ng_xml.should be_equivalent_to @exp_xml
    end

  end

  context "Blank template" do

    it "should match our expectations" do
      exp_xml = %Q(
        #{@mods_start}
          <originInfo>
            <dateOther/>
          </originInfo>
          <abstract/>
          <titleInfo>
            <title/>
          </titleInfo>
          <name>
            <namePart/>
            <role>
              <roleTerm/>
            </role>
          </name>
          <relatedItem>
            <titleInfo>
              <title/>
            </titleInfo>
            <identifier type="uri"/>
            <note type="preferred citation"/>
          </relatedItem>
          <subject>
            <topic/>
          </subject>
          <note type="preferred citation"/>
        </mods>
      )
      exp_xml = noko_doc(exp_xml)
      @dsdoc = Hydrus::DescMetadataDS.new(nil, nil)
      @dsdoc.ng_xml.should be_equivalent_to exp_xml
    end

  end

end
