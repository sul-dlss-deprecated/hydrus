require 'spec_helper'
require 'rake'

describe Hydrus::ObjectFile do

  before(:each) do
    @nm = 'mock_uploaded_file_'
    @hof = Hydrus::ObjectFile.new
    @hof.file = Tempfile.new(@nm)
  end

  it "can exercise getters" do
    @hof.size.should == 0
    @hof.url.should =~ /\/#{@nm}/
    @hof.current_path.should =~ /\/#{@nm}/
    @hof.filename.should =~ /\A#{@nm}/
  end

  describe "set_file_info()" do

    it "should make no changes if given nil" do
      @hof.should_not_receive('label=')
      @hof.set_file_info(nil).should == false
    end

    it "should make no changes if passed new values equivalent to current values" do
      # Set current values.
      lab = 'foobar'
      hid = false
      @hof.label = lab
      @hof.hide = hid
      # Call setter with equivalent values.
      @hof.should_not_receive('label=')
      @hof.set_file_info('label' => lab, 'hide' => 'no').should == false
      @hof.set_file_info('label' => lab).should == false
      # Final check.
      @hof.label.should == lab
      @hof.hide.should == hid
    end

    it "should make changes if passed new values that differ from current values" do
      # Set current values.
      lab = 'foobar'
      hid = false
      @hof.label = lab
      @hof.hide = hid
      # Call setter with equivalent values.
      @hof.set_file_info('label' => 'foo', 'hide' => 'yes').should == true
      @hof.set_file_info('label' => 'foo').should == true
      @hof.set_file_info('hide' => 'yes').should == true
      @hof.set_file_info('label' => 'bar', 'hide' => 'yes').should == true
      # Final check.
      @hof.label.should == 'bar'
      @hof.hide.should == true
    end

  end

end
