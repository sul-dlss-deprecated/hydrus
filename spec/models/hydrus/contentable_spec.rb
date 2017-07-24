require 'spec_helper'

describe Hydrus::Contentable, type: :model do
  before(:each) do
    @go       = Hydrus::GenericObject.new
    @pid      = 'oo000oo9999'
    @base_dir = File.join(Rails.root,Settings.hydrus.file_upload_path,'./oo/000/oo/9999/oo000oo9999')
    allow(@go).to receive(:pid).and_return(@pid)
  end

  it 'base_file_directory()' do
    expect(@go.base_file_directory).to match(/#{Regexp.escape(@base_dir)}\z/)
  end

  it 'content_directory() and metadata_directory()' do
    allow(@go).to receive(:base_file_directory).and_return(@base_dir)
    expect(@go.content_directory).to  eq(@base_dir + '/content')
    expect(@go.metadata_directory).to eq(@base_dir + '/metadata')
  end

  describe 'create_content_metadata_xml()' do
    it 'non-item should get blank XML node' do
      exp = ''
      allow(@go).to receive('is_item?').and_return(false)
      expect(@go.create_content_metadata_xml).to be_equivalent_to(exp)
    end

    it 'item should get real contentMetadata' do
      mock_files = [
        double('fileA', current_path: 'Rakefile', label: 'fileA', hide: false),
        double('fileB', current_path: 'Gemfile',  label: 'fileB', hide: true),
      ]
      exp = '
        <contentMetadata objectId="oo000oo9999" type="file">
          <resource id="oo000oo9999_1" sequence="1" type="file">
            <label>fileA</label>
            <file id="Rakefile" preserve="yes" publish="yes" shelve="yes"/>
          </resource>
          <resource id="oo000oo9999_2" sequence="2" type="file">
            <label>fileB</label>
            <file id="Gemfile" preserve="yes" publish="no" shelve="no"/>
          </resource>
        </contentMetadata>
      '
      allow(@go).to receive('is_item?').and_return(true)
      allow(@go).to receive(:files).and_return(mock_files)
      expect(@go.create_content_metadata_xml).to be_equivalent_to(exp)
    end
  end
end
