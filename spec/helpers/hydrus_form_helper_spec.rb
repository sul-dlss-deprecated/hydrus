require 'spec_helper'

describe HydrusFormHelper, type: :helper do
  include HydrusFormHelper

  describe 'hydrus form label' do
    it 'should return the appropriate HTML when no options are sent' do
      expect(hydrus_form_label { 'My Label:' }).to have_selector 'div.span1'
      expect(hydrus_form_label { 'My Label:' }).to match(/^<div.*>My Label:<\/div>$/)
    end
    it 'should apply columns passed in the options hash' do
      expect(hydrus_form_label(columns: '7') { 'My Label:' }).to have_selector 'div.span7'
    end
    it 'should apply classes passed in the options hash' do
      expect(hydrus_form_label(class: 'my-super cool-class') { 'My Label:' }).to have_selector 'div.my-super.cool-class'
    end
  end

  describe 'hydrus form value' do
    it 'should return the appropriate HTML when no options are sent' do
      expect(hydrus_form_value { "<input type='text' />" }).to have_selector 'div.span8'
      expect(hydrus_form_value { "<input type='text' />".html_safe }).to have_selector "div.span8 input[type='text']"
    end
    it 'should apply columns passed in the options hash' do
      expect(hydrus_form_value(columns: '3') { "<input type='text' />" }).to have_selector 'div.span3'
    end
    it 'should apply classes passed in the options hash' do
      expect(hydrus_form_value(class: 'my-super cool-class') { "<input type='text' />" }).to have_selector 'div.my-super.cool-class'
    end
  end

  describe 'hydrus form header' do
    it 'should return the appropirate HTML when no options are sent' do
      expect(hydrus_form_header { 'Title and contact' }).to(have_selector '.row .span9 h4') &&
      expect(hydrus_form_header { 'Title and contact' }).to(match(/<h4>Title and contact<\/h4>/))
    end
    it 'should apply the required element when the required option is sent' do
      expect(hydrus_form_header(required: true) { 'Title' }).to have_selector '.row .span9 .required'
    end
  end
end
