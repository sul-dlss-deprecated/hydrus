require 'spec_helper'

describe Hydrus::ControllerHelper do
  
  include Hydrus::ControllerHelper

  it "parse_keywords() should do the right thing" do
    s = " \t  foo,bar  , fubb, blah blah , ack \t\n"
    parse_keywords(s).should == {0=>"foo", 1=>"bar", 2=>"fubb", 3=>"blah blah", 4=>"ack"}
    parse_keywords('  ').should == {}
  end

end
