# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  # Helper class to compose ability configurations with a DSL.
  class Recorder

    def initialize(store, ability_class)
      @store = store
      @ability_class = ability_class
    end

    # Execute the permission blocks of the corresponding ability class
    # to generate the abilities.
    def run
      @ability_class.abilities.each do |subject_class, permission_blocks|
        @subject_class = subject_class
        permission_blocks.each do |block|
          instance_eval(&block)
        end
      end
    end

    def permission(permission)
      unless (Role::Permissions + [:any]).include?(permission)
        fail "Unknown permission #{permission.inspect}"
      end
      Permission.new(@store, @ability_class, @subject_class, permission)
    end

    def general(*actions)
      General.new(@store, @ability_class, @subject_class, actions)
    end

    def class_side(*actions)
      ClassSide.new(@store, @ability_class, @subject_class, actions)
    end

    class Base

      def initialize(store, ability_class, subject_class)
        @store = store
        @ability_class = ability_class
        @subject_class = subject_class
      end

      def method_missing(name, *args)
        if args.blank? && @ability_class.constraint_methods.include?(name)
          constraint(name)
          nil
        else
          fail "No constraint #{name} defined in #{@ability_class}"
        end
      end

      private

      def constraint(_constraint)
        # implement in subclass
      end

      def add_config(permission, action, constraint)
        @store.add(AbilityDsl::Config.new(permission,
                                          @subject_class,
                                          action,
                                          @ability_class,
                                          constraint))
      end

    end

    class Permission < Base

      def initialize(store, ability_class, subject_class, permission)
        super(store, ability_class, subject_class)
        @permission = permission
      end

      def may(*actions)
        @actions = actions
        self
      end

      private

      def constraint(constraint)
        @actions.each do |action|
          add_config(@permission, action, constraint)
        end
      end

    end

    class General < Base

      ALL_ACTION = :_all
      PERMISSION = :_general

      def initialize(store, ability_class, subject_class, actions)
        super(store, ability_class, subject_class)
        @actions = actions
      end

      private

      def constraint(constraint)
        (@actions.presence || [ALL_ACTION]).each do |action|
          add_config(PERMISSION, action, constraint)
        end
      end

    end

    class ClassSide < Base
      PERMISSION = :_class_side

      def initialize(store, ability_class, subject_class, actions)
        super(store, ability_class, subject_class)
        @actions = actions
      end

      private

      def constraint(constraint)
        @actions.each do |action|
          add_config(PERMISSION, action, constraint)
        end
      end
    end
  end
end
