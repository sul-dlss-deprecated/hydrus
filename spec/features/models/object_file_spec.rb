require 'spec_helper'
require 'rake'

describe Hydrus::ObjectFile, :integration=>true do

  fixtures :object_files

  it "should find four files associated with the first item and it should grab the url of a given file" do
    pid = 'druid:oo000oo0001'
    files = Hydrus::ObjectFile.find_all_by_pid(pid)
    files.size.should == 4
    f = files[0]
    exp_url = '/uploads/oo/000/oo/0001/oo000oo0001/content/pinocchio.htm'
    f.url.should == exp_url
    f.current_path.should == "#{Rails.root}/public#{exp_url}"
    files[1].filename.should == %q{pinocchio characters tc in file name.pdf}
    files[1].size.should > 0
  end

  it "should delete a file from the file system and disassociate from item when called" do
    pid = 'druid:oo000oo0001'
    @hi=Hydrus::Item.find(pid)

    files = @hi.files
    files.size.should == 4

    filename = files[0].filename
    file_url = files[0].url
    full_file_path = "public" + file_url
    File.exists?(full_file_path).should be_true

    files[0].destroy

    @hi=Hydrus::Item.find(pid)
    @hi.files.size.should == 3
    File.exists?(full_file_path).should be_false

    # restore original file and stream from fixtures
    restore_upload_file(file_url)
    File.exists?(full_file_path).should be_true
  end

end
