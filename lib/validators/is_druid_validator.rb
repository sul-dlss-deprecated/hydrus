# frozen_string_literal: true
class IsDruidValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if DruidTools::Druid.valid?(value)
    record.errors[attribute] << (options[:message] || 'is not a valid druid')
  end

end
