#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class TokenAbility
  include CanCan::Ability

  attr_reader :token

  delegate :dynamic_user_ability, to: :token

  def initialize(token)
    return if token.nil?
    @token = token

    define_token_abilities
  end

  def user
    token.dynamic_user
  end

  def identifier
    "token-#{token.id}"
  end

  private

  def define_token_abilities
    define_base_abilities
    define_person_abilities if token.people?
    define_event_abilities if token.events?
    define_group_abilities if token.groups?
    define_role_abilities if token.people? && token.groups?
    define_invoice_abilities if token.invoices?
    define_event_participation_abilities if token.event_participations?
    define_mailing_list_abilities if token.mailing_lists?
  end

  def define_base_abilities
    can :index, Group
  end

  def define_role_abilities
    can :index, Role
    can :show, Role do |role|
      dynamic_user_ability.can? :show_full, role.person
    end
    can [:create, :update, :destroy], Role do |role|
      dynamic_user_ability.can?(:update, role.group) &&
        dynamic_user_ability.can?(:update, role.person)
    end
  end

  def define_person_abilities # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    below_permissions =
      token.layer_and_below_read? || token.layer_and_below_full?
    groups = below_permissions ? token_layer_and_below : [token.layer]

    can :show, [Person, PersonDecorator] do |p|
      Role.where(person: p, group: groups).present? &&
        dynamic_user_ability.can?(:show, p)
    end

    can :show_full, [Person, PersonDecorator] do |p|
      Role.where(person: p, group: groups).present? &&
        dynamic_user_ability.can?(:show_full, p)
    end

    can :show_details, [Person, PersonDecorator] do |p|
      Role.where(person: p, group: groups).present? &&
        dynamic_user_ability.can?(:show_details, p)
    end

    can :index_people, Group do |g|
      groups.include?(g)
    end

    can :update, [Person, PersonDecorator] do |p|
      Role.where(person: p, group: groups).present? &&
        dynamic_user_ability.can?(:update, p)
    end
  end

  def define_event_abilities
    can :list_available, Event

    can :show, Event do |e|
      e.groups.any? { |g| token_layer_and_below.include?(g) }
    end

    can :index_events, Group do |g|
      token_layer_and_below.include?(g)
    end

    can :"index_event/courses", Group do |g|
      token_layer_and_below.include?(g)
    end

    can :read, Event::Kind
    can :read, Event::KindCategory
  end

  def define_event_participation_abilities
    can :show, Event::Participation do |p|
      p.event.groups.collect(&:layer_group).any? { |g| token.layer == g }
    end

    can :index_participations, Event do |event|
      event.groups.collect(&:layer_group).any? { |g| token.layer == g }
    end
  end

  def define_group_abilities
    can :show, Group do |g|
      token_layer_and_below.include?(g)
    end

    can :show_details, Group do |g|
      token_layer_and_below.include?(g)
    end
  end

  def define_invoice_abilities
    can :index_invoices, Group do |group|
      token.layer == group
    end

    can [:read, :update], Invoice, {group: {layer_group_id: token.layer.id}}
    can [:read, :update], InvoiceItem, {invoice: {group: {layer_group_id: token.layer.id}}}
  end

  def define_mailing_list_abilities
    can :show, MailingList do |mailing_list|
      token.layer.layer_group == mailing_list.group.layer_group
    end

    can :index_subscriptions, MailingList do |mailing_list|
      token.layer.layer_group == mailing_list.group.layer_group
    end
  end

  def token_layer_and_below
    token.layer.self_and_descendants
  end

  def write_permission?
    token.permission =~ /_full$/
  end
end
