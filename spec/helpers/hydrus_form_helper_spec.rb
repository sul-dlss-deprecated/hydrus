require File.expand_path('../../spec_helper', __FILE__)

describe HydrusFormHelper do
  include HydrusFormHelper
  
  describe "hydrus form label" do
    it "should return the appropriate HTML when no options are sent" do
      hydrus_form_label{"My Label:"}.should have_selector "div.span2"
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
      hydrus_form_value{"<input type='text' />"}.should have_selector "div.span7"
      hydrus_form_value{"<input type='text' />"}.should have_selector "div.span7 input[type='text']"
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
      hydrus_form_header{"Title"}.should have_selector ".row .span8 h3" and 
      hydrus_form_header{"Title"}.should match(/<h3>Title<\/h3>/)
    end
    it "should apply the required element when the required option is sent" do
       hydrus_form_header(:required=>true){"Title"}.should have_selector ".row .span1 .required"
    end
    
  end
  
end