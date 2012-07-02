require 'spec_helper'

describe Hydrus::AccessControlsEnforcement do
  
  include Hydrus::AccessControlsEnforcement

  describe "exclude_unwanted_models()" do

    it "should should add an :fq key" do
      solr_parameters = {}
      user_parameters = {}
      exclude_unwanted_models(solr_parameters, user_parameters)
      solr_parameters.has_key?(:fq).should == true
      solr_parameters[:fq].should be_kind_of Array
    end

    it "should not modify :fq value if it is already present" do
      solr_parameters = {:fq => 123}
      user_parameters = {}
      exclude_unwanted_models(solr_parameters, user_parameters)
      solr_parameters[:fq].should == 123
    end

  end

end
