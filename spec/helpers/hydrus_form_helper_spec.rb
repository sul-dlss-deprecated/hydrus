require 'spec_helper'

describe HydrusFormHelper do
  include HydrusFormHelper

  describe "hydrus form label" do
    it "should return the appropriate HTML when no options are sent" do
      hydrus_form_label{"My Label:"}.should have_selector "div.span1"
      hydrus_form_label{"My Label:"}.should match(/^<div.*>My Label:<\/div>$/)
    end
    it "should apply columns passed in the options hash" do
      hydrus_form_label(:columns=>"7"){"My Label:"}.should have_selector "div.span7"
    end
    it "should apply classes passed in the options hash" do
      hydrus_form_label(:class=>"my-super cool-class"){"My Label:"}.should have_selector "div.my-super.cool-class"
    end
  end

  describe "hydrus form value" do
    it "should return the appropriate HTML when no options are sent" do
      hydrus_form_value{"<input type='text' />"}.should have_selector "div.span8"
      hydrus_form_value{"<input type='text' />".html_safe}.should have_selector "div.span8 input[type='text']"
    end
    it "should apply columns passed in the options hash" do
      hydrus_form_value(:columns=>"3"){"<input type='text' />"}.should have_selector "div.span3"
    end
    it "should apply classes passed in the options hash" do
      hydrus_form_value(:class=>"my-super cool-class"){"<input type='text' />"}.should have_selector "div.my-super.cool-class"
    end
  end

  describe "hydrus form header" do
    it "should return the appropirate HTML when no options are sent" do
      hydrus_form_header{"Title and contact"}.should have_selector ".row .span9 h4" and
      hydrus_form_header{"Title and contact"}.should match(/<h4>Title and contact<\/h4>/)
    end
    it "should apply the required element when the required option is sent" do
       hydrus_form_header(:required=>true){"Title"}.should have_selector ".row .span9 .required"
    end
  end

end
