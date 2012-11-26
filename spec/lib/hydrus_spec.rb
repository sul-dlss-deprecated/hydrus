require 'spec_helper'
require 'stringio'

describe "ap_dump()" do

  it "should write some stuff to the given file handle" do
    message     = 'blah blah'
    data        = [1111, 2222]
    file_handle = StringIO.new
    Hydrus.ap_dump(message, data, file_handle)
    s = file_handle.string
    s.should include(message)
    s.should =~ /^=====/
    data.each { |d| s.should include(d.to_s) }
    s.should =~ /=====$/
  end

end
