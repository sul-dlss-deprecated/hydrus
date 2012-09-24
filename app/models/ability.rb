class Ability
  include CanCan::Ability
  include Hydra::Ability
  
  # TODO Add actual access control enforcement
  def hydra_default_permissions user, session    
    can :manage, :all if user.email.present?
  end
end

__END__

class Ability
  include CanCan::Ability


  can? :edit, @fedora_object
  can? :edit, 'changeme:5'


  # XXX Disable access control enforcement for this iteration
  def hydra_default_permissions user, session
  #  can :manage, :all if user.email.present?
    can :read, String do |pid|
      obj = ActiveFedora::Base.find(pid, :cast => true)
      Dor::Authorization.check_if_user_can_read_obj(user, obj)
    end

    can :read, ActiveFedora::Base do |obj|
      Dor::Authorization.check_if_user_can_read_obj(user, obj)
    end

    can :edit do |pid|

    end
  end
end

https://github.com/projecthydra/hydra-head/tree/master/hydra-access-controls
https://github.com/projecthydra/hydra-head/blob/master/hydra-access-controls/lib/hydra/policy_aware_access_controls_enforcement.rb
