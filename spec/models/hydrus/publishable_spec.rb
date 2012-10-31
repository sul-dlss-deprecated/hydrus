require 'spec_helper'

# A mock class to use while testing out mixin.
class MockPublishable
  include Hydrus::Publishable
  include Hydrus::ModelHelper  
  def initialize(sv)
    @should_validate = sv
  end
end

describe Hydrus::Publishable do

  describe "should_validate()" do

    it "should not call is_submitted() when @should_validate is true" do
      obj = MockPublishable.new(true)
      obj.should_not_receive(:is_submitted)
      obj.should_validate.should == true
    end

    it "should return the value of is_submitted() when @should_validate is false" do
      obj = MockPublishable.new(nil)
      [false, true, false].each do |exp|
        obj.stub(:is_submitted).and_return(exp)
        obj.should_validate.should == exp
      end
    end

  end

  describe "is_publishable() should return value of valid?" do

    it "and should not address the APO for non-Collections" do
      pending "will refactor is_publishable()"
      next

      obj = MockPublishable.new(false)
      obj.should_not_receive(:apo)
      obj.stub(:is_published).and_return(false)      
      obj.stub(:requires_human_approval).and_return('no')      
      obj.stub(:'valid?').and_return(true)
      obj.stub(:'is_collection?').and_return(false)      
      obj.is_publishable.should == true
      obj.stub(:'valid?').and_return(false)
      obj.is_publishable.should == false
    end
    
    it "and should address the APO for Collections" do
      pending "will refactor is_publishable()"
      next

      obj = Hydrus::Collection.new
      apo = MockPublishable.new(false)
      obj.stub(:is_published).and_return(false)      
      obj.should_receive(:apo).exactly(4).times
      obj.stub(:'is_collection?').and_return(true)      
      obj.stub(:'valid?').and_return(true)
      obj.is_publishable.should == true
      obj.stub(:'valid?').and_return(false)
      obj.is_publishable.should == false
    end
    
  end

end
