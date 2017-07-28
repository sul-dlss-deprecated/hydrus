# frozen_string_literal: true

require 'spec_helper'

describe IsDruidValidator do
  describe 'validate_each()' do
    before(:each) do
      @validator = IsDruidValidator.new({attributes: {pid: true}})
      @mock_record = double('mock_record', errors: {})
      allow(@mock_record.errors).to receive('[]').and_return([])
    end

    it 'should not report an error if the druid is valid' do
      expect(@mock_record).not_to receive('errors')
      @validator.validate_each(@mock_record, 'druid', 'aa000aa0000')
    end

    it 'should report an error if the druid is invalid' do
      expect(@mock_record).to receive('errors')
      @validator.validate_each(@mock_record, 'druid', 'foobar')
    end
  end
end
