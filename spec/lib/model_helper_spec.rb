require 'spec_helper'

describe Hydrus::AccessControlsEnforcement do
  
  include Hydrus::ModelHelper

  it "to_bool() should convert true-like things to true" do
    tests = {
      'true'  => true,
      'yes'   => true,
      true    => true,
      false   => false,
      'false' => false,
      'no'    => false,
      'blah'  => false,
      123     => false,
    }
    tests.each { |inp, exp| to_bool(inp).should == exp }
  end

  it "parse_comma_delimited() should work as expected" do
    tests = {
      '  a  , b, c  '       => %w(a b c),
      ' a b  , c, d e  f  ' => ['a b', 'c', 'd e  f'],
      ' a b '               => ['a b'],
      ' foo '               => ['foo'],
      '  '                  => [],
    }
    tests.each { |inp, exp| parse_comma_delimited(inp).should == exp }
  end

end
