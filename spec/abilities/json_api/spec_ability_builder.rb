# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  module SpecAbilityBuilder
    def build_ability(&block)
      Class.new do
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
      end.new
    end
  end
end
