require 'ostruct'

class Hydrus::GenericModel < OpenStruct
  include ActiveModel::Validations
  include Hydrus::ModelHelper

  # FIXME: This is a hack. It would be preferable if we knew what attributes each
  # model supported.
  # @return [Array<Symbol>] a list of the defined properties
  def attribute_names
    @table.keys
  end
end
