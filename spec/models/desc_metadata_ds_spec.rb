require 'spec_helper'

describe Hydrus::DescMetadataDS do

  context "Marshalling to and from a Fedora Datastream" do

    before(:each) do
      sloc = "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd"
      @dsxml = <<-EOF
        <mods xmlns="http://www.loc.gov/mods/v3"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              version="3.3"
              xsi:schemaLocation="#{sloc}">
          <originInfo>
            <publisher>publisher content</publisher>
            <dateIssued>Nov 7</dateIssued>
            <place>
              <placeTerm type="text">placeTerm content 1</placeTerm>
              <placeTerm type="BLAH">placeTerm content 2</placeTerm>
              <placeTerm type="text">placeTerm content 3</placeTerm>
            </place>
          </originInfo>
          <coordinates>coordinates content</coordinates>
          <extent>extent content</extent>
          <scale>scale content</scale>
          <topic>top1</topic>
          <topic>top2</topic>
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
          </relatedItem>
          <subject>
            <topic>divorce</topic>
            <topic>marriage</topic>
          </subject>
          <note type="Preferred Citation">pref_cite</note>
          <note type="peer-review">Indeed</note>
        </mods>
      EOF
      
      @dsdoc = Hydrus::DescMetadataDS.from_xml(@dsxml)
    end
    
    it "should get correct values from OM terminology" do
      tests = [
        [[:originInfo, :publisher],          'publisher content'],
        [[:originInfo, :dateIssued],         'Nov 7'],
        [[:originInfo, :place, :placeTerm],  ['placeTerm content 1', 'placeTerm content 3']],
        [[:originInfo, :place, :placeTerm],  ['placeTerm content 1', 'placeTerm content 3']],
        [:coordinates,                       'coordinates content'],
        [:extent,                            'extent content'],
        [:scale,                             'scale content'],
        [:topic,                             ['top1', 'top2', 'divorce', 'marriage']],
        [:abstract,                          'abstract content'],
        [:title,                             'Learn VB in 21 Days'],
        [[:name, :namePart],                 'Angus'],
        [[:name, :role, :roleTerm],          'guitar'],
        [[:relatedItem, :titleInfo, :title], 'Learn VB in 1 Day'],
        [[:relatedItem, :identifier],        'http://example.com'],
        [[:subject, :topic],                 ['divorce', 'marriage']],
        [:preferred_citation,                'pref_cite'],
        [:peer_reviewed,                     'Indeed'],
      ]
      tests.each do |terms, exp|
        terms = [terms] unless terms.class == Array
        exp   = [exp]   unless exp.class == Array
        @dsdoc.term_values(*terms).should == exp
      end
    end

  end
    
end
