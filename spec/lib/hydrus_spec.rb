require 'spec_helper'
require 'stringio'

describe "ap_dump()" do

  it "should write some stuff to the given file handle" do
    data        = [1111, 2222]
    file_handle = StringIO.new
    Hydrus.ap_dump(data, file_handle)
    s = file_handle.string
    expect(s).to include('hydrus_spec.rb')
    expect(s).to match(/\A========/)
    data.each { |d| expect(s).to include(d.to_s) }
    expect(s).to match(/========\n\z/)
  end

end
