#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DoorkeeperTokenAbility
  include CanCan::Ability

  attr_reader :token, :user_ability

  delegate :identifier, :user_context, to: :user_ability

  def user
    user_ability.user
  end

  def initialize(doorkeeper_token)
    return if doorkeeper_token.nil?
    @token = doorkeeper_token
    @user_ability = Ability.new(Person.find(doorkeeper_token.resource_owner_id))

    if token.acceptable?(:api)
      define_all_abilities
    else
      define_token_abilities
    end
  end

  private

  # rubocop:todo Metrics/CyclomaticComplexity
  # rubocop:todo Metrics/AbcSize
  def define_token_abilities
    define_group_abilities if token.acceptable?(:groups)
    define_event_abilities if token.acceptable?(:events)
    define_event_participation_abilities if token.acceptable?(:event_participations)
    define_person_abilities if token.acceptable?(:people)
    define_role_abilities if token.acceptable?(:groups) && token.acceptable?(:people)
    define_invoice_abilities if token.acceptable?(:invoices)
    define_mailing_list_abilities if token.acceptable?(:mailing_lists)
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def define_all_abilities
    define_group_abilities
    define_event_abilities
    define_event_participation_abilities
    define_person_abilities
    define_role_abilities
    define_invoice_abilities
    define_mailing_list_abilities
  end

  def define_group_abilities
    can :show, Group do |g|
      user_ability.can?(:show, g)
    end

    can :index, Group do |g|
      user_ability.can?(:index, g)
    end
  end

  # rubocop:todo Metrics/AbcSize
  # rubocop:todo Metrics/MethodLength
  def define_event_abilities
    can :list_available, Event do |e|
      user_ability.can?(:list_available, e)
    end

    can :index_events, Group do |g|
      user_ability.can?(:index_events, g)
    end

    can :"index_event/courses", Group do |g|
      user_ability.can?(:"index_event/courses", g)
    end

    can :show, Event do |e|
      user_ability.can?(:show, e)
    end

    can :read, Event::Kind do
      user_ability.can?(:list_available, Event)
    end

    can :read, Event::KindCategory do
      user_ability.can?(:list_available, Event)
    end

    can :index, Event::Course do |p|
      user_ability.can?(:index, p)
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def define_event_participation_abilities
    can :index, Event::Participation do |p|
      user_ability.can?(:index, p)
    end

    can :show, Event::Participation do |p|
      user_ability.can?(:show, p)
    end
  end

  def define_person_abilities
    can :show, Person do |p|
      user_ability.can?(:show, p)
    end

    can :show_details, Person do |p|
      user_ability.can?(:show_details, p)
    end

    can :show_full, Person do |p|
      user_ability.can?(:show_full, p)
    end

    can :index_people, Group do |g|
      user_ability.can?(:index_people, g)
    end

    can :update, Person do |p|
      user_ability.can?(:update, p)
    end
  end

  # rubocop:todo Metrics/AbcSize
  # rubocop:todo Metrics/MethodLength
  def define_role_abilities
    can :index, Role do |role|
      user_ability.can?(:index, role.group) &&
        user_ability.can?(:index, role.person)
    end

    can :show, Role do |role|
      user_ability.can?(:show, role.group) &&
        user_ability.can?(:show, role.person)
    end
    can :create, Role do |role|
      user_ability.can?(:update, role.group) &&
        user_ability.can?(:update, role.person)
    end
    can :update, Role do |role|
      user_ability.can?(:update, role.group) &&
        user_ability.can?(:update, role.person)
    end
    can :destroy, Role do |role|
      user_ability.can?(:update, role.group) &&
        user_ability.can?(:update, role.person)
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def define_invoice_abilities
    can :index, Invoice do |i|
      user_ability.can?(:index, i)
    end

    can :show, Invoice do |i|
      user_ability.can?(:show, i)
    end

    can :update, Invoice do |i|
      user_ability.can?(:update, i)
    end

    can :index_issued_invoices, Group do |g|
      user_ability.can?(:index_issued_invoices, g)
    end
  end

  def define_mailing_list_abilities
    can :index, MailingList do |m|
      user_ability.can?(:index, m)
    end

    can :show, MailingList do |m|
      user_ability.can?(:show, m)
    end

    can :index_subscriptions, MailingList do |m|
      user_ability.can?(:index_subscriptions, m)
    end

    can :index_mailing_lists, Group do |g|
      user_ability.can?(:index_mailing_lists, g)
    end

    # the index action shows a mailing list if it's either subscribable
    # or the user has write permissions on the parent group, therefoe we also
    # need to map the :update ability from the user corresponding to the
    # oauth token in order to support that logic
    can :update, Group do |g|
      user_ability.can?(:update, g)
    end
  end
end
