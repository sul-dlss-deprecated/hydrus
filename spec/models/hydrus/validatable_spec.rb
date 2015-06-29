require 'spec_helper'

class MockValidatable
  include Hydrus::Validatable
  def initialize(sv = nil)
    @should_validate = sv
  end
end

describe Hydrus::Validatable, :type => :model do

  describe "should_validate()" do

    it "should not call is_draft() when @should_validate is true" do
      obj = MockValidatable.new(true)
      expect(obj).not_to receive(:is_draft)
      expect(obj.should_validate).to eq(true)
    end

    it "should return the value of not(is_draft) when @should_validate is false" do
      obj = MockValidatable.new
      [false, true, false, true].each do |exp|
        allow(obj).to receive(:is_draft).and_return(exp)
        expect(obj.should_validate).to eq(!exp)
      end
    end

  end

  describe "validate!" do

    it "should return the value of valid?, but cached, so always equivalent to the first setting, including when @should_validate is false" do
      obj = MockValidatable.new
      first_value=false
      [first_value, true, false, true].each do |exp|
        allow(obj).to receive('valid?').and_return(exp)
        expect(obj.validate!).to eq(first_value)
      end
    end

    it "should return the value of valid? including when @should_validate is false" do
      [false, true, false, true].each do |exp|
        obj = MockValidatable.new
        allow(obj).to receive('valid?').and_return(exp)
        expect(obj.validate!).to eq(exp)
      end
    end

    it "should restore @should_validate to its prior value" do
      exp = 1234
      obj = MockValidatable.new(exp)
      expect(obj).to receive('valid?')
      obj.validate!
      expect(obj.instance_variable_get('@should_validate')).to eq(exp)
    end

  end

end
