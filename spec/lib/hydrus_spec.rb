require 'spec_helper'
require 'stringio'

describe "ap_dump()" do

  it "should write some stuff to the given file handle" do
    data        = [1111, 2222]
    file_handle = StringIO.new
    Hydrus.ap_dump(data, file_handle)
    s = file_handle.string
    s.should include('hydrus_spec.rb')
    s.should =~ /\A========/
    data.each { |d| s.should include(d.to_s) }
    s.should =~ /========\n\z/
  end

end
