class Hydrus::GenericModel
  
  def initialize(params={})
    params.each {|key,value| instance_variable_set "@#{key.to_s}", value }
  end

end