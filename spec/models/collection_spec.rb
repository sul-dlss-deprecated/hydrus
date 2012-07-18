require 'spec_helper'

describe Hydrus::Collection do
    
  it "should be valid unless publish is set on both the apo and the collection" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.should be_valid
    col.apo.should be_valid
    col.object_valid?.should == true  
  end

  it "should have the associated apo deposit status set correctly when the collection is published" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.publish.should == false
    col.apo.deposit_status.should == ''
    col.clicked_publish?.should == false
    col.publish="true"
    col.apo.deposit_status.should == 'open'
    col.apo.open_for_deposit?.should == true
    col.publish="false"
    col.apo.deposit_status.should == 'closed'
    col.apo.open_for_deposit?.should == false
  end

  it "new collections that are published should be invalid if required fields are not set, including those on the APO" do
    col=Hydrus::Collection.new(:pid=>'druid:tt000tt0001')
    col.should be_valid
    col.apo.should be_valid
    col.object_valid?.should == true
    col.apo.deposit_status.should == ''
    col.apo.open_for_deposit?.should == false
    col.publish=true
    col.apo.deposit_status.should == 'open'
    col.apo.open_for_deposit?.should == true    
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
    col.contact='test@test.com'
    col.embargo_option='none'
    col.license_option='none'
    col.object_valid?.should == true    
    col.embargo_option='varies'
    col.object_valid?.should == false    
    col.embargo='1 year'
    col.object_valid?.should == true
  end

  
end