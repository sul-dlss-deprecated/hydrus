require 'spec_helper'
require 'rake'

RSpec.describe Hydrus::ObjectFile, type: :feature, integration: true do
  fixtures :object_files
  let(:pid) { 'druid:bb123bb1234' }

  describe '.where' do
    subject(:files) { described_class.where(pid: pid) }
    it 'finds four files associated with the first item and it grabs the url of a given file' do
      expect(files.size).to eq(4)
      f = files[0]
      exp_url = '/file/druid:bb123bb1234/pinocchio.htm'
      expect(f.url).to eq(exp_url)
      expect(f.current_path).to eq("#{Rails.root}/uploads/bb/123/bb/1234/bb123bb1234/content/pinocchio.htm")
      expect(files[1].filename).to eq(%q{pinocchio characters tc in file name.pdf})
      expect(files[1].size).to be > 0
    end
  end

  it 'should delete a file from the file system and disassociate from item when called' do
    @hi = Hydrus::Item.find(pid)

    files = @hi.files
    expect(files.size).to eq(4)
    file = files.first
    full_file_path = file.current_path
    expect(File.exists?(full_file_path)).to be_truthy

    file.destroy

    @hi = Hydrus::Item.find(pid)
    expect(@hi.files.size).to eq(3)
    expect(File.exists?(full_file_path)).to be_falsey

    # restore original file and stream from fixtures
    restore_upload_file(file)
    expect(File.exists?(full_file_path)).to be_truthy
  end
end
