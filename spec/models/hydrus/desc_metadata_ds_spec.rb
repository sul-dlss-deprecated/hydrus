require 'spec_helper'

describe Hydrus::DescMetadataDS, type: :model do

  before(:all) do
    sloc = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd'
    @mods_start = <<-EOF
      <mods xmlns="http://www.loc.gov/mods/v3"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            version="3.3"
            xsi:schemaLocation="#{sloc}">
    EOF
  end

  context 'Marshalling to and from a Fedora Datastream' do

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

    it 'should get correct values from OM terminology' do
      expect(@dsdoc.term_values(:abstract)).to eq(['abstract content'])
      expect(@dsdoc.term_values(:main_title)).to eq(['Learn VB in 21 Days'])
      expect(@dsdoc.term_values(:name, :namePart)).to eq(['Angus'])
      expect(@dsdoc.term_values(:name, :role, :roleTerm)).to eq(['guitar'])
      expect(@dsdoc.term_values(:relatedItem, :titleInfo, :title)).to eq(['Learn VB in 1 Day'])
      expect(@dsdoc.term_values(:relatedItem, :location, :url)).to eq(['http://example.com'])
      expect(@dsdoc.term_values(:subject, :topic)).to eq(['divorce', 'marriage'])
      expect(@dsdoc.term_values(:preferred_citation)).to eq(['pref_cite outer'])
      expect(@dsdoc.term_values(:related_citation)).to eq(['related_cite outer'])
      expect(@dsdoc.term_values(:contact)).to eq(%w(foo@bar.com blah@bar.com))
    end

  end

  context 'Inserting new nodes' do

    it 'Should be able to insert new XML nodes' do
      nm = '<name type="personal"><namePart>NAME</namePart><role><roleTerm authority="marcrelator" type="text">ROLE</roleTerm></role></name>'
      ri = '<relatedItem><titleInfo><title/></titleInfo><location><url/></location></relatedItem>'
      rc = '<note type="citation/reference" displayLabel="Related Publication"></note>'
      to = '<subject><topic>foo</topic></subject>'
      @exp_xml = noko_doc([
        @mods_start,
        to,
        ri, ri,
        rc,
        to,
        nm, nm,
        '</mods>',
      ].join '')
      @dsdoc   = Hydrus::DescMetadataDS.from_xml("#{@mods_start}</mods>")
      @dsdoc.insert_topic('foo')
      @dsdoc.insert_contributor('personal', 'NAME', 'ROLE')
      @dsdoc.insert_contributor('personal', 'NAME', 'ROLE')
      @dsdoc.insert_related_item
      @dsdoc.insert_related_citation
      @dsdoc.insert_related_item
      @dsdoc.insert_topic('foo')
      expect(@dsdoc.ng_xml).to be_equivalent_to @exp_xml
    end

  end

  context 'Blank template' do

    it 'should match our expectations' do
      exp_xml = %Q(
        #{@mods_start}
          <abstract/>
          <titleInfo>
            <title/>
          </titleInfo>
          <name>
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="text"/>
            </role>
          </name>
          <originInfo>
               <dateCreated/>
          </originInfo>
          <typeOfResource/>
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
      expect(@dsdoc.ng_xml).to be_equivalent_to exp_xml
    end

  end

end
