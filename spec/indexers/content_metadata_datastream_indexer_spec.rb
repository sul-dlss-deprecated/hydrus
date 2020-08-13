# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContentMetadataDatastreamIndexer do
  let(:xml) do
    <<~XML
            <?xml version="1.0"?>
      <contentMetadata objectId="druid:gw177fc7976" type="map" stacks="/specialstack">
      <resource id="0001" sequence="1" type="image">
      <file format="JPEG2000" id="gw177fc7976_05_0001.jp2" mimetype="image/jp2" preserve="yes" publish="yes" shelve="yes" size="5143883">
      <imageData height="4580" width="5939"/>
      <checksum type="md5">3d3ff46d98f3d517d0bf086571e05c18</checksum>
      <checksum type="sha1">ca1eb0edd09a21f9dd9e3a89abc790daf4d04916</checksum>
      </file>
      <file format="GIF" id="gw177fc7976_05_0001.gif" mimetype="image/gif" preserve="no" publish="no" shelve="no" size="4128877" role="derivative">
      <imageData height="4580" width="5939"/>
      <checksum type="md5">406d5d80fdd9ecc0352d339badb4a8fb</checksum>
      <checksum type="sha1">61940d4fad097cba98a3e9dd9f12a90dde0be1ac</checksum>
      </file>
      <file format="TIFF" id="gw177fc7976_00_0001.tif" mimetype="image/tiff" preserve="yes" publish="no" shelve="no" size="81630420">
      <imageData height="4580" width="5939"/>
      <checksum type="md5">81ccd17bccf349581b779615e82a0366</checksum>
      <checksum type="sha1">12586b624540031bfa3d153299160c4885c3508c</checksum>
      </file>
      </resource>
      </contentMetadata>
    XML
  end

  let(:obj) { Dor::Item.new }

  let(:indexer) do
    described_class.new(resource: obj)
  end

  before do
    obj.contentMetadata.content = xml
  end

  describe '#to_solr' do
    subject(:doc) { indexer.to_solr }

    it 'has the fields used by argo' do
      expect(doc).to include(
        'content_type_ssim' => 'map',
        'content_file_mimetypes_ssim' => ['image/jp2', 'image/gif', 'image/tiff'],
        'content_file_roles_ssim' => ['derivative'],
        'shelved_content_file_count_itsi' => 1,
        'resource_count_itsi' => 1,
        'content_file_count_itsi' => 3,
        'image_resource_count_itsi' => 1,
        'first_shelved_image_ss' => 'gw177fc7976_05_0001.jp2',
        'preserved_size_dbtsi' => 86_774_303,
        'shelved_size_dbtsi' => 5_143_883
      )
    end
  end
end
