require 'spec_helper'
require 'stringio'

describe "ap_dump()" do
  
  it "should write some stuff to the given file handle" do
    d = [0, 1, 2]
    file_handle = StringIO.new
    Hydrus.ap_dump(d, file_handle)
    s = file_handle.string
    s.should =~ /^=====/
    s.should =~ /=====$/
  end

end
