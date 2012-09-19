require 'spec_helper'

# A mock class to use while testing out mixin.
class MockPublishable
  include Hydrus::Publishable
  def initialize(sv)
    @should_validate = sv
  end
end

describe Hydrus::Publishable do

  describe "should_validate()" do

    it "should return true directly if @should_validate is true" do
      obj = MockPublishable.new(true)
      obj.should_not_receive(:is_published)
      obj.should_validate.should == true
    end
    
    it "should return value of is_published() when @should_validate is false" do
      obj = MockPublishable.new(false)
      obj.should_receive(:is_published).and_return(true)
      obj.should_validate.should == true
      obj.should_receive(:is_published).and_return(false)
      obj.should_validate.should == false
    end
    
  end

  describe "is_publishable() should return value of valid?" do

    it "and should not address the APO for non-Collections" do
      obj = MockPublishable.new(false)
      obj.should_not_receive(:apo)
      obj.stub(:'valid?').and_return(true)
      obj.stub(:'is_collection?').and_return(false)      
      obj.is_publishable.should == true
      obj.stub(:'valid?').and_return(false)
      obj.is_publishable.should == false
    end
    
    it "and should address the APO for Collections" do
      obj = Hydrus::Collection.new
      apo = MockPublishable.new(false)
      obj.should_receive(:apo).exactly(4).times
      obj.stub(:'is_collection?').and_return(true)      
      obj.stub(:'valid?').and_return(true)
      obj.is_publishable.should == true
      obj.stub(:'valid?').and_return(false)
      obj.is_publishable.should == false
    end
    
  end

end
