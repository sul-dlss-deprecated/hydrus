# We need a custom validator so we can be sure for required items
# that we don't have a one element array with a single blank element.

class IsDruidValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    # What is the purpose of the if clause?
    if value.blank? || !value.downcase.include?('druid')
      unless DruidTools::Druid.valid?(value)
        record.errors[attribute] << (options[:message] || "is not a valid druid") 
      end
    end
  end

end
