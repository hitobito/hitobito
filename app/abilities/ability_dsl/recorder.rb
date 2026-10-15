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
        raise "Unknown permission #{permission.inspect}"
      end
      Permission.new(@store, @ability_class, @subject_class, permission)
    end

    def general(*actions)
      General.new(@store, @ability_class, @subject_class, actions)
    end

    def class_side(*actions)
      ClassSide.new(@store, @ability_class, @subject_class, actions)
    end

    # All ability conditions in such a block are granted if either the current user
    # or one of their manageds (children) individually is granted the ability.
    # In other words, if the abilities defined in a for_self_or_manageds block are granted
    # to my child, I automatically get the same abilities.
    def for_self_or_manageds
      return unless block_given?

      original_include_manageds = AbilityDsl::Recorder::Base.include_manageds
      AbilityDsl::Recorder::Base.include_manageds = true
      yield
      AbilityDsl::Recorder::Base.include_manageds = original_include_manageds
    end

    class Base
      class_attribute :include_manageds

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
          raise "No constraint #{name} defined in #{@ability_class}"
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
          constraint,
          {include_manageds: include_manageds}))
      end
    end

    class Permission < Base
      def initialize(store, ability_class, subject_class, permission)
        super(store, ability_class, subject_class)
        @permission = permission
        @attr_config = nil
      end

      def may(*actions)
        @actions = actions
        self
      end

      # Declare which attributes are permitted (allowlist) for this permission/action/constraint.
      # Usage:
      #   permission(:any).may(:update).permitted_attrs(:last_name, :nickname).herself
      def permitted_attrs(*attrs)
        @attr_config = {attrs: attrs, kind: :permit}
        self
      end

      # Declare which attributes are excluded (denylist) for this permission/action/constraint.
      # All other attributes remain permitted.
      # Usage:
      #   permission(:any).may(:update).except_attrs(:first_name).herself
      def except_attrs(*attrs)
        @attr_config = {attrs: attrs, kind: :except}
        self
      end

      private

      def constraint(constraint)
        method = @attr_config.present? ? :attribute_constraint : :general_constraint
        @actions.each do |action|
          send(method, action, constraint)
        end
      end

      def general_constraint(action, constraint)
        add_config(@permission, action, constraint)
      end

      def attribute_constraint(action, constraint)
        # For kind == :except, we need a regular can rule (broad permission)
        # plus an attribute config that will generate a cannot rule.
        # For :permit, we only need the attribute config (can with attrs).
        general_constraint(action, constraint) if @attr_config[:kind] == :except

        @store.add_attribute_config(
          AbilityDsl::AttributeConfig.new(
            @permission, @subject_class, action, @ability_class, constraint,
            @attr_config[:attrs], @attr_config[:kind]
          )
        )
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
