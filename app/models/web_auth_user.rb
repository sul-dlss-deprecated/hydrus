class WebAuthUser
  def initialize(user_id)
    raise "Cannot instantiate WebAuthUser without proper WEBAUTH_USER environment variable." if user_id.blank?
    @id = user_id
  end
  
  def email
    "#{@id}@stanford.edu"
  end
  
  def to_s
    @id
  end
  
  def sunetid
    return @id
  end
  
  def is_webauth?
    true
  end
  
end
