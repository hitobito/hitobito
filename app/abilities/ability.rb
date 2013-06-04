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

  private

  def define(user_context)
    store.configs_for_permissions(user_context.all_permissions) do |c|
      if c.constraint == :all
        can c.action, c.subject_class
      elsif c.constraint != :none
        can c.action, c.subject_class do |subject|
          all_constraints(c).all? do |ability_class, constraints|
            ability = ability_class.new(user_context, subject, c.permission)
            constraints.all? {|constraint| ability.send(constraint) }
          end
        end
      end
    end
  end

  def all_constraints(config)
    general_constraints = store.general_constraints(config.subject_class, config.action)
    permission_constraint = {config.ability_class => [config.constraint]}
    general_constraints.each_with_object(permission_constraint).each do |g, constraints|
      constraints[g.ability_class] ||= []
      constraints[g.ability_class] << g.constraint
    end
  end

end


