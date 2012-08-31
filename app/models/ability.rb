class Ability
  include CanCan::Ability
  include Hydra::Ability

  # TODO Add actual access control enforcement
  def hydra_default_permissions user, session
    can :manage, :all if user.email.present?
  end
end
