# frozen_string_literal: true
class WebAuthUser
  attr_reader :groups

  def initialize(user_id, request_env = {})
    raise 'Cannot instantiate WebAuthUser without proper WEBAUTH_USER environment variable.' if user_id.blank?
    @id = user_id
    @groups = request_env.fetch('WEBAUTH_LDAPPRIVGROUP', '').split('|')
  end

  def email
    "#{@id}@stanford.edu"
  end

  def to_s
    @id
  end

  def sunetid
    @id
  end

  def is_webauth?
    true
  end
  
  def is_administrator?
    groups.include? 'dlss:hydrus-app-administrators'
  end
  
  def is_collection_creator?
    is_administrator? || groups.include?('dlss:hydrus-app-collection-creators')
  end
  
  def is_global_viewer?
    is_administrator? || groups.include?('dlss:hydrus-app-global-viewers')
  end

end
