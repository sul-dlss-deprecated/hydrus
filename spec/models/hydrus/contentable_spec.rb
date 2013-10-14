require 'spec_helper'

describe Hydrus::Contentable do

  before(:each) do
    @go       = Hydrus::Item.new
    @pid      = 'oo000oo9999'
    @base_dir = '/oo/000/oo/9999/oo000oo9999'
    @go.stub(:pid).and_return(@pid)
  end

  it "base_file_directory()" do
    @go.base_file_directory.should =~ /#{Regexp.escape(@base_dir)}\z/
  end

  it "content_directory() and metadata_directory()" do
    @go.stub(:base_file_directory).and_return(@base_dir)
    @go.content_directory.should  == @base_dir + '/content'
    @go.metadata_directory.should == @base_dir + '/metadata'
  end

  describe "create_content_metadata_xml()" do

    it "non-item should get blank XML node" do
      exp = ''
      @go.stub('is_item?').and_return(false)
      @go.create_content_metadata_xml.should be_equivalent_to(exp)
    end

    it "item should get real contentMetadata" do
      mock_files = [
        double('fileA', :current_path => 'Rakefile', :label => 'fileA', :hide => false),
        double('fileB', :current_path => 'Gemfile',  :label => 'fileB', :hide => true),
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
      @go.stub('is_item?').and_return(true)
      @go.stub(:files).and_return(mock_files)
      @go.create_content_metadata_xml.should be_equivalent_to(exp)
    end

  end

end
