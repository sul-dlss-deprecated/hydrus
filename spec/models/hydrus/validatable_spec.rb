require 'spec_helper'

class MockValidatable
  include Hydrus::Validatable
  def initialize(sv = nil)
    @should_validate = sv
  end
end

describe Hydrus::Validatable do

  describe "should_validate()" do

    it "should not call is_draft() when @should_validate is true" do
      obj = MockValidatable.new(true)
      obj.should_not_receive(:is_draft)
      obj.should_validate.should == true
    end

    it "should return the value of not(is_draft) when @should_validate is false" do
      obj = MockValidatable.new
      [false, true, false, true].each do |exp|
        obj.stub(:is_draft).and_return(exp)
        obj.should_validate.should == !exp
      end
    end

  end

  describe "validate!" do

    it "should return the value of valid?, including when @should_validate is false" do
      obj = MockValidatable.new
      [false, true, false, true].each do |exp|
        obj.stub('valid?').and_return(exp)
        obj.validate!.should == exp
      end
    end

    it "should restore @should_validate to its prior value" do
      exp = 1234
      obj = MockValidatable.new(exp)
      obj.should_receive('valid?')
      obj.validate!
      obj.instance_variable_get('@should_validate').should == exp
    end

  end

end
