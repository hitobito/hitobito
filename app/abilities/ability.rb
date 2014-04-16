# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
    return if user.nil?

    if user.root?
      can :manage, :all
      # root cannot change her email, because this is what makes her root.
      cannot :update_email, Person do |p|
        p.root?
      end
    else
      define(AbilityDsl::UserContext.new(user))
    end
  end

  private

  def define(user_context)
    store.configs_for_permissions(user_context.all_permissions) do |c|
      if c.constraint == :all
        general_constraints = general_constraints(c)
        if general_constraints.present?
          can_with_block(general_constraints, c, user_context)
        else
          can c.action, c.subject_class
        end
      elsif c.constraint != :none
        can_with_block(all_constraints(c), c, user_context)
      end
    end
  end

  def can_with_block(constraints, c, user_context)
    can c.action, c.subject_class do |subject|
      action_allowed?(constraints, user_context, c, subject)
    end
  end

  def general_constraints(config)
    general_constraints = store.general_constraints(config.subject_class, config.action)
    general_constraints.each_with_object({}).each do |g, constraints|
      append_constraint(constraints, g)
    end
  end

  def all_constraints(config)
    append_constraint(general_constraints(config), config)
  end

  def append_constraint(constraints, config)
    constraints[config.ability_class] ||= []
    constraints[config.ability_class] << config.constraint
    constraints
  end

  def action_allowed?(constraint_hash, user_context, c, subject)
    constraint_hash.all? do |ability_class, constraints|
      ability = ability_class.new(user_context, subject, c.permission)
      constraints.all? { |constraint| ability.send(constraint) }
    end
  end

end
