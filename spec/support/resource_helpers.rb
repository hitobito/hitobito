#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

module ResourceHelpers
  extend ActiveSupport::Concern

  included do
    before do
      set_ability { can :manage, :all }
    end
  end

  def set_ability(permit_read: true, &block)
    ability = Class.new do
      include CanCan::Ability

      define_method(:initialize) do
        can :read, Person if permit_read
        instance_eval(&block) if block
      end
    end
    Graphiti.context[:object].current_ability = ability.new
  end
end
