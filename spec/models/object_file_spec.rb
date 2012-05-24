require 'spec_helper'

describe Hydrus::ObjectFile do
  fixtures :object_files
    
  it "should find four files associated with the first item and it should grab the url of a given file" do
    pid = 'druid:oo000oo0001'
    files = Hydrus::ObjectFile.find_all_by_pid(pid)
    files.size.should == 4
    files[0].url.should == '/uploads/oo/000/oo/0001/pinocchio.htm'
    files[1].filename.should == %q{pinocchio characters tc in file name.pdf}
  end

end
