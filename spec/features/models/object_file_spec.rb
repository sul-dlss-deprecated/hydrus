# frozen_string_literal: true
require 'spec_helper'
require 'rake'

describe Hydrus::ObjectFile, type: :feature, integration: true do
  fixtures :object_files

  it 'should find four files associated with the first item and it should grab the url of a given file' do
    pid = 'druid:oo000oo0001'
    files = Hydrus::ObjectFile.where(pid: pid)
    expect(files.size).to eq(4)
    f = files[0]
    exp_url = '/uploads/oo/000/oo/0001/oo000oo0001/content/pinocchio.htm'
    expect(f.url).to eq(exp_url)
    expect(f.current_path).to eq("#{Rails.root}/public#{exp_url}")
    expect(files[1].filename).to eq(%q{pinocchio characters tc in file name.pdf})
    expect(files[1].size).to be > 0
  end

  it 'should delete a file from the file system and disassociate from item when called' do
    pid = 'druid:oo000oo0001'
    @hi=Hydrus::Item.find(pid)

    files = @hi.files
    expect(files.size).to eq(4)
    file = files.first

    file_url = file.url
    full_file_path = file.current_path
    expect(File.exists?(full_file_path)).to be_truthy

    file.destroy

    @hi=Hydrus::Item.find(pid)
    expect(@hi.files.size).to eq(3)
    expect(File.exists?(full_file_path)).to be_falsey

    # restore original file and stream from fixtures
    restore_upload_file(file_url)
    expect(File.exists?(full_file_path)).to be_truthy
  end
end
