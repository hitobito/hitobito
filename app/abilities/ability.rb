# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
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
    ContactAccountAbility,
    EventAbility,
    Event::ApplicationAbility,
    Event::InvitationAbility,
    Event::ParticipationAbility,
    Event::ParticipationContactDataAbility,
    Event::RoleAbility,
    Event::QuestionTemplateAbility,
    GroupAbility,
    InvoiceAbility,
    MailingListAbility,
    MessageAbility,
    NoteAbility,
    OauthAbility,
    PassAbility,
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

  if FeatureGate.enabled? "personal_documents"
    store.register PersonalDocumentAbility
  end

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
    user.root? ? Group.layers.pluck(:id) : user_context.permission_layer_ids(:finance)
  end

  private

  def define_root_abilities
    can :manage, :all
    # root cannot change her email, because this is what makes her root.
    cannot :update_email, Person, email: Settings.root_email
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
        # Only consider permissions which the manager can inherit from the managed
        store = current_store.filter_configs { |_, _, _, config| config.options[:include_manageds] }

        define_instance_side(store, user_context)
        define_class_side(store, user_context)
      end
    end
  end

  def define_instance_side(current_store, current_user_context)
    evaluator = AbilityDsl::ConstraintEvaluator.new(current_user_context)
    current_store.configs_for_permissions(current_user_context.all_permissions) do |c|
      can_with_condition(c.action, c.subject_class, evaluator.condition(c))
    end
  end

  def define_class_side(current_store, current_user_context)
    evaluator = AbilityDsl::ConstraintEvaluator.new(current_user_context)
    current_store.class_side_constraints do |c|
      can c.action, c.subject_class if evaluator.class_side_allowed?(c)
    end
  end

  def can_with_condition(action, subject_class, condition)
    case condition
    when nil then nil
    when AbilityDsl::Condition::AnyOf
      condition.operands.each { |operand| can_with_condition(action, subject_class, operand) }
    when AbilityDsl::Condition then can action, subject_class, id: condition
    else can action, subject_class, condition
    end
  end

  def inspect # Avoid excessive logs in backtrace
    user_context.inspect
  end
end
