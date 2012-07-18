class Ability
  include CanCan::Ability
  include Hydra::Ability

  # XXX Disable access control enforcement for this iteration
  def hydra_default_permissions user, session
    can :manage, :all if user.email.present?
  end
end
