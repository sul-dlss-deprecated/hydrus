require 'spec_helper'

RSpec.describe HydrusFormHelper, type: :helper do
  include HydrusFormHelper

  describe 'hydrus form label' do
    it 'should return the appropriate HTML when no options are sent' do
      expect(hydrus_form_label { 'My Label:' }).to have_selector 'div.col-sm-1'
      expect(hydrus_form_label { 'My Label:' }).to match(/^<div.*>My Label:<\/div>$/)
    end
    it 'should apply columns passed in the options hash' do
      expect(hydrus_form_label(columns: '7') { 'My Label:' }).to have_selector 'div.col-sm-7'
    end
    it 'should apply classes passed in the options hash' do
      expect(hydrus_form_label(class: 'my-super cool-class') { 'My Label:' }).to have_selector 'div.my-super.cool-class'
    end
  end

  describe 'hydrus form value' do
    it 'should return the appropriate HTML when no options are sent' do
      expect(hydrus_form_value { "<input type='text' />" }).to have_selector 'div.col-sm-8'
      expect(hydrus_form_value { "<input type='text' />".html_safe }).to have_selector "div.col-sm-8 input[type='text']"
    end
    it 'should apply columns passed in the options hash' do
      expect(hydrus_form_value(columns: '3') { "<input type='text' />" }).to have_selector 'div.col-sm-3'
    end
    it 'should apply classes passed in the options hash' do
      expect(hydrus_form_value(class: 'my-super cool-class') { "<input type='text' />" }).to have_selector 'div.my-super.cool-class'
    end
  end

  describe 'syntax_highlighted_datastream' do
    subject { syntax_highlighted_datastream(obj, dsid) }
    let(:obj) { Dor::Item.new }

    context 'when the dsid is RELS-EXT' do
      let(:dsid) { 'RELS-EXT' }

      it { is_expected.to be_instance_of ActiveSupport::SafeBuffer }
    end
  end
end
