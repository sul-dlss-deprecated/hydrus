require 'ostruct'

class Hydrus::GenericModel < OpenStruct

  include ActiveModel::Validations
  include Hydrus::ModelHelper
  
end
