# we need a custom validator to check for the existence of at least one associated model in multi-value fields -- also confirm they are valid
class AtLeastOneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank? || (value.class == Array && value.collect{|x| x.valid?}.include?(false)) 
      record.errors[attribute] << (options[:message] || "must have at least one valid entry")
    end
  end
end
