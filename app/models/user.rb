class User < ActiveRecord::Base
  include Hydra::User
  include Blacklight::User

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  #attr_accessible :email, :password, :password_confirmation, :remember_me

  # Blacklight uses #to_s on your user class to get
  # a user-displayable login/identifier for the account.
  def to_s
    sunetid
  end

  def sunetid
    email.split('@').first
  end

  def is_webauth?
    false
  end

  def is_administrator?
    false
  end

  def is_collection_creator?
    false
  end

  def is_global_viewer?
    false
  end
end
