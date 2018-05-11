class User < ActiveRecord::Base
  include Hydra::User
  include Blacklight::User

  devise :remote_user_authenticatable

  # Blacklight uses #to_s on your user class to get
  # a user-displayable login/identifier for the account.
  def to_s
    sunetid
  end

  def sunetid
    email.split('@').first
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
