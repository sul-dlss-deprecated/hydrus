# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DescribableIndexer do
  let(:xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <mods:mods xmlns:mods="http://www.loc.gov/mods/v3"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 version="3.3"
                 xsi:schemaLocation="http://www.loc.gov/mods/v3 http://cosimo.stanford.edu/standards/mods/v3/mods-3-3.xsd">
         <mods:titleInfo>
            <mods:nonSort>The</mods:nonSort>
            <mods:title>complete works of Henry George</mods:title>
         </mods:titleInfo>
         <mods:name type="personal">
            <mods:namePart>George, Henry</mods:namePart>

            <mods:namePart type="date">1839-1897</mods:namePart>
            <mods:role>
               <mods:roleTerm authority="marcrelator" type="text">creator</mods:roleTerm>
            </mods:role>
         </mods:name>
         <mods:name type="personal">
            <mods:namePart>George, Henry</mods:namePart>

            <mods:namePart type="date">1862-1916</mods:namePart>
         </mods:name>
         <mods:typeOfResource>text</mods:typeOfResource>
         <mods:originInfo>
            <mods:place>
               <mods:placeTerm type="code" authority="marccountry">xx</mods:placeTerm>
            </mods:place>

            <mods:place>
               <mods:placeTerm type="text">Garden City, N. Y</mods:placeTerm>
            </mods:place>
            <mods:publisher>Doubleday, Page</mods:publisher>
            <mods:dateIssued>1911</mods:dateIssued>
            <mods:dateIssued encoding="marc" keyDate="yes">1911</mods:dateIssued>
            <mods:edition>[Library ed.]</mods:edition>

            <mods:issuance>monographic</mods:issuance>
         </mods:originInfo>
         <mods:language>
            <mods:languageTerm authority="iso639-2b" type="code">eng</mods:languageTerm>
         </mods:language>
         <mods:relatedItem type="original">
            <mods:physicalDescription>
               <mods:form authority="marcform">print</mods:form>

               <mods:extent>10 v. fronts (v. 1-9) ports. 21 cm.</mods:extent>
            </mods:physicalDescription>
            <mods:recordInfo>
               <mods:recordContentSource authority="marcorg">YNG</mods:recordContentSource>
               <mods:recordCreationDate encoding="marc">731210</mods:recordCreationDate>
               <mods:recordChangeDate encoding="iso8601">19900625062034.0</mods:recordChangeDate>
               <mods:recordIdentifier source="SUL catalog key">68184</mods:recordIdentifier>

               <mods:recordIdentifier source="oclc">757655</mods:recordIdentifier>
            </mods:recordInfo>
         </mods:relatedItem>
         <mods:physicalDescription>
            <mods:form authority="marcform">electronic</mods:form>
            <mods:reformattingQuality>preservation</mods:reformattingQuality>
            <mods:digitalOrigin>reformatted digital</mods:digitalOrigin>

         </mods:physicalDescription>
         <mods:tableOfContents>I. Progress and poverty.--II. Social problems.--III. The land question. Property in land. The condition of labor.--IV. Protection or free trade.--V. A perplexed philosopher [Herbert Spencer]--VI. The science of political economy, books I and II.--VII. The science of political economy, books III to V. "Moses": a lecture.--VIII. Our land and land policy.--IX-X. The life of Henry George, by his son Henry George, jr.</mods:tableOfContents>
         <mods:note>On cover: Complete works of Henry George. Fels fund. Library edition.</mods:note>
         <mods:subject authority="lcsh">
            <mods:topic>Economics</mods:topic>
            <mods:temporal>1800-1900</mods:temporal>
         </mods:subject>
         <mods:recordInfo>

            <mods:recordContentSource>DOR_MARC2MODS3-3.xsl Revision 1.1</mods:recordContentSource>
            <mods:recordCreationDate encoding="iso8601">2011-02-25T18:20:23.132-08:00</mods:recordCreationDate>
            <mods:recordIdentifier source="Data Provider Digital Object Identifier">36105010700545</mods:recordIdentifier>
         </mods:recordInfo>
         <mods:identifier type="local" displayLabel="SUL Resource ID">druid:pz263ny9658</mods:identifier>
         <mods:location>
            <mods:physicalLocation>Stanford University Libraries</mods:physicalLocation>

            <mods:url>http://purl.stanford.edu/pz263ny9658</mods:url>
         </mods:location>
      </mods:mods>
    XML
  end
  let(:obj) { Dor::Abstract.new }

  let(:indexer) do
    described_class.new(resource: obj)
  end

  describe '#to_solr' do
    let(:doc) { indexer.to_solr }

    before do
      obj.datastreams['descMetadata'].content = xml
    end

    it 'includes values from stanford_mods' do
      expect(doc).to match a_hash_including(
        'sw_language_ssim' => ['English'],
        'sw_format_ssim' => ['Book'],
        'sw_subject_temporal_ssim' => ['1800-1900'],
        'sw_pub_date_sort_ssi' => '1911',
        'sw_pub_date_facet_ssi' => '1911'
      )
    end

    it 'does not include empty values' do
      doc.keys.sort_by(&:to_s).each do |k|
        expect(doc).to include(k)
        expect(doc).to match hash_excluding(k => nil)
        expect(doc).to match hash_excluding(k => [])
      end
    end
  end
end
