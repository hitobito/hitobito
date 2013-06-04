class Ability

  include CanCan::Ability

  cattr_reader :store
  @@store = AbilityDsl::Store.new

  store.register EventAbility,
                 Event::ApplicationAbility,
                 Event::ParticipationAbility,
                 Event::RoleAbility,
                 GroupAbility,
                 MailingListAbility,
                 PeopleFilterAbility,
                 PersonAbility,
                 QualificationAbility,
                 RoleAbility,
                 SubscriptionAbility,
                 VariousAbility


  def initialize(user)
    if user.root?
      can :manage, :all
    else
      define(AbilityDsl::UserContext.new(user))
    end
  end

  def define(user_context)
    store.configs_for_permissions(user_context.all_permissions) do |c|
      if c.constraint == :all
        can c.action, c.subject_class
      elsif c.constraint != :none
        can c.action, c.subject_class do |subject|
          ability = c.ability_class.new(user_context, subject, c.permission)
          general = store.general_constraints(c.subject_class, c.action)

          general.all? {|constraint| ability.send(constraint) } &&
            ability.send(c.constraint)
        end
      end
    end
  end

end

