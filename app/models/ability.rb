class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, User, id: user.id
    can :manage, Shop, user_id: user.id
  end
end
