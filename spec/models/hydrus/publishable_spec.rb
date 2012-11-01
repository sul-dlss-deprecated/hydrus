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

    it "should not call is_draft() when @should_validate is true" do
      obj = MockPublishable.new(true)
      obj.should_not_receive(:is_draft)
      obj.should_validate.should == true
    end

    it "should return the value of not(is_draft) when @should_validate is false" do
      obj = MockPublishable.new(nil)
      [false, true, false].each do |exp|
        obj.stub(:is_draft).and_return(exp)
        obj.should_validate.should == !exp
      end
    end

  end

end
