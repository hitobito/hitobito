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

  def set_user(user)
    Graphiti.context[:object].current_ability = Ability.new(user)
  end

  def set_ability(ability: nil, &block)
    return Graphiti.context[:object].current_ability = ability if ability.present?

    ability = Class.new do
      include CanCan::Ability
      attr_reader :user

      define_method(:initialize) do
        @user = Fabricate(:person)
        @self_before_instance_eval = eval "self", block.binding
        instance_eval(&block)
      end

      def method_missing(method, *args, &block)
        @self_before_instance_eval.send method, *args, &block
      end
    end

    Graphiti.context[:object].current_ability = ability.new
  end
end
