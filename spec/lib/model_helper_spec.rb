require 'spec_helper'

describe Hydrus::AccessControlsEnforcement do

  include Hydrus::ModelHelper

  it 'to_bool() should convert true-like things to true' do
    expect(to_bool('true')).to eq(true)
    expect(to_bool('yes')).to eq(true)
    expect(to_bool(true)).to eq(true)
    expect(to_bool(false)).to eq(false)
    expect(to_bool('false')).to eq(false)
    expect(to_bool('no')).to eq(false)
    expect(to_bool('blah')).to eq(false)
    expect(to_bool(123)).to eq(false)
  end

  it 'parse_delimited() should work as expected' do
    expect(Hydrus::ModelHelper.parse_delimited('  a  , b, c  ')).to eq(%w(a b c))
    expect(Hydrus::ModelHelper.parse_delimited('a,b,c;')).to eq(%w(a b c))
    expect(Hydrus::ModelHelper.parse_delimited("  a  \n b \n c  ")).to eq(%w(a b c))
    expect(Hydrus::ModelHelper.parse_delimited(' a b  , c, d e  f  ')).to eq(['a b', 'c', 'd e  f'])
    expect(Hydrus::ModelHelper.parse_delimited(' a b ')).to eq(['a b'])
    expect(Hydrus::ModelHelper.parse_delimited(' foo ')).to eq(['foo'])
    expect(Hydrus::ModelHelper.parse_delimited('  ')).to eq([])
    expect(Hydrus::ModelHelper.parse_delimited("  a,,; b \n\r  , c\nd  ")).to eq(%w(a b c d))
  end

  it 'equal_when_stripped?' do
    expect(equal_when_stripped?(' hi ', 'hi')).to eq(true)
    expect(equal_when_stripped?(' hi ', 'HI')).to eq(false)
    expect(equal_when_stripped?([1,2], [1,2])).to eq(true)
    expect(equal_when_stripped?(['hi'], ['hi '])).to eq(false)
  end

end
