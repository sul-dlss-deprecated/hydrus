require 'spec_helper'

describe Hydrus::Collection do
    
  it "should be valid unless publish is set on both the apo and the collection" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.should be_valid
    col.apo.should be_valid
    col.object_valid?.should == true
  end

  it "should have the associated apo set to published when the collection is published" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.publish.should == nil
    col.apo.publish.should == nil
    col.clicked_publish?.should == false
    col.publish=true
    col.apo.publish.should == true
    col.clicked_publish?.should == true
    col.apo.clicked_publish?.should == true    
  end

  it "new collections that are published should be invalid if required fields are not set, including those on the APO" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.should be_valid
    col.apo.should be_valid
    col.object_valid?.should == true
    col.publish="true"
    col.should_not be_valid
    col.apo.should_not be_valid
    col.object_valid?.should == false
    col.object_error_messages[:title].should_not be_nil
    col.object_error_messages[:embargo].should_not be_nil    
    col.object_error_messages[:abstract].should_not be_nil    
  end

  it "new collections that are published should be valid when options are correctly set" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.publish="true"
    col.object_valid?.should == false
    col.title='title'
    col.abstract='abstract'
    col.embargo_option='none'
    col.object_valid?.should == true    
    col.embargo_option='varies'
    col.object_valid?.should == false    
    col.embargo='1 year'
    col.object_valid?.should == true
  end

  
end