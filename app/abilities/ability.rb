# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Ability
  include CanCan::Ability
  prepend Draper::CanCanCan

  cattr_reader :store
  @@store = AbilityDsl::Store.new

  store.register AssignmentAbility,
    CalendarAbility,
    EventAbility,
    Event::ApplicationAbility,
    Event::InvitationAbility,
    Event::ParticipationAbility,
    Event::ParticipationContactDataAbility,
    Event::RoleAbility,
    GroupAbility,
    InvoiceAbility,
    MailingListAbility,
    MessageAbility,
    NoteAbility,
    OauthAbility,
    PeopleFilterAbility,
    PeopleManagerAbility,
    PersonAbility,
    Person::AddRequestAbility,
    QualificationAbility,
    RoleAbility,
    SelfRegistrationReasonAbility,
    ServiceTokenAbility,
    SubscriptionAbility,
    TagAbility,
    VariousAbility

  attr_reader :user_context

  def user
    user_context&.user
  end

  def initialize(user)
    return if user.nil?

    @user_context = AbilityDsl::UserContext.new(user)

    if user.root?
      define_root_abilities
    else
      define_user_abilities(store, @user_context)
    end
  end

  def identifier
    "user-#{user.id}"
  end

  def user_finance_layer_ids
    user_context.permission_layer_ids(:finance)
  end

  private

  def define_root_abilities
    can :manage, :all
    # root cannot change her email, because this is what makes her root.
    cannot :update_email, Person do |p|
      p.root?
    end
  end

  def define_user_abilities(current_store, current_user_context, include_manageds = true)
    define_instance_side(current_store, current_user_context)
    define_class_side(current_store, current_user_context)

    # Adds to the option to specify ability conditions like this:
    # on(Event) do
    #   for_self_or_manageds do
    #     permission(:foo).may(:bar).some_condition
    #   end
    # end
    # The condition will then grant permission when either the logged in user or one
    # of their manageds is granted permission. I.e. the logged in user inherits the
    # permissions of his manageds.
    # Technically, this is implemented by normally generating the "can :foo, :bar"
    # statements from the stored ability configs, and then for each of the manageds
    # generating additional "can :foo, :bar" statements (but only the ones which
    # originate inside a for_self_or_manageds block in the ability DSL).
    if include_manageds
      user.manageds.each do |managed|
        user_context = AbilityDsl::UserContext.new(managed)
        store = current_store.only_manager_inheritable

        define_instance_side(store, user_context)
        define_class_side(store, user_context)
      end
    end
  end

  def define_instance_side(current_store, current_user_context)
    current_store.configs_for_permissions(user_context.all_permissions) do |c|
      if c.constraint == :all
        general_can(c, current_store, current_user_context)
      elsif c.constraint != :none
        constrained_can(c, current_store, current_user_context)
      end
    end
  end

  def define_class_side(current_store, current_user_context)
    current_store.class_side_constraints do |c|
      if class_side_action_allowed?(c, current_user_context)
        can c.action, c.subject_class
      end
    end
  end

  def general_can(c, current_store, current_user_context)
    general = general_constraints(c, current_store)
    if general.present?
      can_with_block(general, c, current_user_context)
    else
      can c.action, c.subject_class
    end
  end

  def constrained_can(c, current_store, current_user_context)
    can_with_block(all_constraints(c, current_store), c, current_user_context)
  end

  def can_with_block(constraints, c, current_user_context)
    can c.action, c.subject_class do |subject|
      action_allowed?(constraints, c.permission, subject, current_user_context)
    end
  end

  def class_side_action_allowed?(c, current_user_context)
    constraints = {c.ability_class => [c.constraint]}
    return true if c.constraint == :everybody
    return false if c.constraint == :nobody
    action_allowed?(constraints, :any, c.subject_class, current_user_context)
  end

  def general_constraints(config, current_store)
    general_constraints = current_store.general_constraints(config.subject_class, config.action)
    general_constraints.each_with_object({}).each do |g, constraints|
      append_constraint(constraints, g)
    end
  end

  def all_constraints(config, current_store)
    append_constraint(general_constraints(config, current_store), config)
  end

  def append_constraint(constraints, config)
    constraints[config.ability_class] ||= []
    constraints[config.ability_class] << config.constraint
    constraints
  end

  def action_allowed?(constraint_hash, permission, subject, current_user_context)
    constraint_hash.all? do |ability_class, constraints|
      ability = ability_class.new(current_user_context, subject, permission)
      constraints.all? { |constraint| ability.send(constraint) }
    end
  end
end
