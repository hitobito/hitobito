# encoding: utf-8

#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class TokenAbility

  include CanCan::Ability

  attr_reader :token

  def initialize(token)
    return if token.nil?
    @token = token

    define_token_abilities
  end

  private

  def define_token_abilities
    define_person_abilities if token.people? || token.people_below?
    define_event_abilities if token.events?
    define_group_abilities if token.groups?
  end

  def define_person_abilities
    groups = token.people_below? ? token_layer_and_below : [token.layer]
    can :show, Person do |p|
      Role.where(person: p, group: groups).present?
    end

    can :index_people, Group do |g|
      groups.include?(g)
    end
  end

  def define_event_abilities
    can :show, Event do |e|
      e.groups.any? { |g| token_layer_and_below.include?(g) }
    end

    can :index_events, Group do |g|
      token_layer_and_below.include?(g)
    end

    can :'index_event/courses', Group do |g|
      token_layer_and_below.include?(g)
    end
  end

  def define_group_abilities
    can :show, Group do |g|
      token_layer_and_below.include?(g)
    end
  end

  def token_layer_and_below
    token.layer.self_and_descendants
  end

end
