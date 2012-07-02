require 'spec_helper'

describe IsDruidValidator do
  
  describe "validate_each()" do

    before(:each) do
      @validator = IsDruidValidator.new({:attributes => {}})
      @mock_record = double('mock_record', :errors => {})
      @mock_record.errors.stub('[]').and_return([])  
    end

    it "should not report an error if the druid is valid" do
      @mock_record.should_not_receive('errors')
      @validator.validate_each(@mock_record, "druid", "aa000aa0000")
    end

    it "should report an error if the druid is invalid" do
      @mock_record.should_receive('errors')
      @validator.validate_each(@mock_record, "druid", "foobar")
    end

  end

end
