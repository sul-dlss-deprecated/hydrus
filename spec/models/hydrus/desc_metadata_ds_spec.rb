require 'spec_helper'

describe Hydrus::DescMetadataDS do

  before(:all) do
    sloc = "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd"
    @mods_start = <<-EOF
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
            <location>
              <url>http://example.com</url>
            </location>
          </relatedItem>
          <subject><topic>divorce</topic></subject>
          <subject><topic>marriage</topic></subject>
          <note type="preferred citation" displayLabel="Preferred Citation">pref_cite outer</note>
          <note type="citation/reference" displayLabel="Related Publication">related_cite outer</note>
          <note type="contact" displayLabel="Contact">foo@bar.com</note>
          <note type="contact" displayLabel="Contact">blah@bar.com</note>
        </mods>
      EOF
      @dsdoc = Hydrus::DescMetadataDS.from_xml(dsxml)
    end

    it "should get correct values from OM terminology" do
      tests = [
        [[:abstract],                        ['abstract content']],
        [[:main_title],                      ['Learn VB in 21 Days']],
        [[:name, :namePart],                 ['Angus']],
        [[:name, :role, :roleTerm],          ['guitar']],
        [[:relatedItem, :titleInfo, :title], ['Learn VB in 1 Day']],
        [[:relatedItem, :location, :url],    ['http://example.com']],
        [[:subject, :topic],                 ['divorce', 'marriage']],
        [[:preferred_citation],              ['pref_cite outer']],
        [[:related_citation],                ['related_cite outer']],
        [[:contact],                         %w(foo@bar.com blah@bar.com)],
      ]
      tests.each do |terms, exp|
        @dsdoc.term_values(*terms).should == exp
      end
    end

  end

  context "Inserting new nodes" do

    it "Should be able to insert new XML nodes" do
      nm = '<name><namePart/><role><roleTerm authority="marcrelator" type="text"/></role></name>'
      ri = '<relatedItem><titleInfo><title/></titleInfo><location><url/></location></relatedItem>'
      rc = '<note type="citation/reference"></note>'
      to = '<subject><topic>foo</topic></subject>'
      @exp_xml = noko_doc([
        @mods_start,
        to,
        nm, nm, nm,
        ri, ri,
        rc,
        to,
        '</mods>',
      ].join '')
      @dsdoc   = Hydrus::DescMetadataDS.from_xml("#{@mods_start}</mods>")
      @dsdoc.insert_topic('foo')
      @dsdoc.insert_person
      @dsdoc.insert_person
      @dsdoc.insert_person
      @dsdoc.insert_related_item
      @dsdoc.insert_related_citation
      @dsdoc.insert_related_item
      @dsdoc.insert_topic('foo')
      @dsdoc.ng_xml.should be_equivalent_to @exp_xml
    end

  end

  context "Blank template" do

    it "should match our expectations" do
      exp_xml = %Q(
        #{@mods_start}
          <abstract/>
          <titleInfo>
            <title/>
          </titleInfo>
          <relatedItem>
            <titleInfo>
              <title/>
            </titleInfo>
            <location>
              <url/>
            </location>
          </relatedItem>
          <subject>
            <topic/>
          </subject>
          <note type="preferred citation" displayLabel="Preferred Citation"/>
          <note type="citation/reference" displayLabel="Related Publication"/>
          <note type="contact" displayLabel="Contact"/>
        </mods>
      )
      exp_xml = noko_doc(exp_xml)
      @dsdoc = Hydrus::DescMetadataDS.new(nil, nil)
      @dsdoc.ng_xml.should be_equivalent_to exp_xml
    end

  end

end
