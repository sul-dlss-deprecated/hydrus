# frozen_string_literal: true

require 'spec_helper'
require 'rake'

describe Hydrus::ObjectFile, type: :model do
  before(:each) do
    @nm = 'mock_uploaded_file_'
    @hof = Hydrus::ObjectFile.new
    @hof.file = Tempfile.new(@nm)
  end

  it 'can exercise getters' do
    expect(@hof.size).to eq(0)
    expect(@hof.url).to match(/\/#{@nm}/)
    expect(@hof.current_path).to match(/\/#{@nm}/)
    expect(@hof.filename).to match(/\A#{@nm}/)
  end

  describe 'set_file_info()' do
    it 'should make no changes if given nil' do
      expect(@hof).not_to receive('label=')
      expect(@hof.set_file_info(nil)).to eq(false)
    end

    it 'should make no changes if passed new values equivalent to current values' do
      # Set current values.
      lab = 'foobar'
      hid = false
      @hof.label = lab
      @hof.hide = hid
      # Call setter with equivalent values.
      expect(@hof).not_to receive('label=')
      expect(@hof.set_file_info('label' => lab, 'hide' => 'no')).to eq(false)
      expect(@hof.set_file_info('label' => lab)).to eq(false)
      # Final check.
      expect(@hof.label).to eq(lab)
      expect(@hof.hide).to eq(hid)
    end

    it 'should make changes if passed new values that differ from current values' do
      # Set current values.
      lab = 'foobar'
      hid = false
      @hof.label = lab
      @hof.hide = hid
      # Call setter with equivalent values.
      expect(@hof.set_file_info('label' => 'foo', 'hide' => 'yes')).to eq(true)
      expect(@hof.set_file_info('label' => 'foo')).to eq(true)
      expect(@hof.set_file_info('hide' => 'yes')).to eq(true)
      expect(@hof.set_file_info('label' => 'bar', 'hide' => 'yes')).to eq(true)
      # Final check.
      expect(@hof.label).to eq('bar')
      expect(@hof.hide).to eq(true)
    end
  end
end
