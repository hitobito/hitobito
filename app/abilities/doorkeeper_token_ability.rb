# encoding: utf-8

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DoorkeeperTokenAbility

  include CanCan::Ability

  attr_reader :token, :user_ability

  def initialize(doorkeeper_token)
    return if doorkeeper_token.nil?
    @token = doorkeeper_token
    @user_ability = Ability.new(Person.find(doorkeeper_token.resource_owner_id))

    define_token_abilities
  end

  private

  def define_token_abilities
    define_group_abilities if (token.acceptable?(:groups) || token.acceptable?(:api))
    define_event_abilities if (token.acceptable?(:events) || token.acceptable?(:api))
    define_person_abilities if (token.acceptable?(:people) || token.acceptable?(:api))
    define_invoice_abilities if (token.acceptable?(:invoices) || token.acceptable?(:api))
  end

  def define_group_abilities
    can :show, Group do |g|
      user_ability.can?(:show, g)
    end

    can :index, Group do |g|
        user_ability.can?(:index, g)
      end
  end

  def define_event_abilities
    can :index_events, Group do |g|
      user_ability.can?(:index_events, g)
    end

    can :'index_event/courses', Group do |g|
      user_ability.can?(:'index_event/courses', g)
    end

    can :show, Event do |e|
      user_ability.can?(:show, e)
    end

    can :show, Event::Participation do |p|
      user_ability.can?(:show, p)
    end

    can :index_participations, Event do |e|
      user_ability.can?(:index_participations, e)
    end
  end

  def define_person_abilities
    can :show, Person do |p|
      user_ability.can?(:show, p)
    end

    can :index_people, Group do |g|
      user_ability.can?(:index_people, g)
    end
  end

  def define_invoice_abilities
    can :show, Invoice do |i|
      user_ability.can?(:show, i)
    end

    can :index_invoices, Group do |g|
      user_ability.can?(:index_invoices, g)
    end
  end

end
