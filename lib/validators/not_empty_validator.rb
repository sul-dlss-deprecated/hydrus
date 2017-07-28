# frozen_string_literal: true
# we need a custom validator so we can be sure for required items that we don't have a one element array with a single blank element
class NotEmptyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank? || (value.class == Array && value.delete_if{|x| x.empty?}.size == 0)
      record.errors[attribute] << (options[:message] || 'cannot be blank')
    end
  end
end
