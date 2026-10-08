# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  # Base class for defining abilities.
  # Abilities are defined for models, usually only for one per ability class.
  # Eg.
  #  on(Person) do
  #    class_side(:index_people_without_role).if_admin
  #
  #    permission(:group_read).may(:show).in_same_group
  #    permission(:layer_and_below_full).may(:update, :destroy).in_same_layer_or_below
  #    general(:send_password_instructions).not_self
  #  end
  #
  # Each permission is defined for one Role::Permission, several actions and one constraint.
  # The constraint is a public instance method of the ability class. It describes the records
  # the rule applies to as a cancancan conditions hash, built from the user and the
  # permission, e.g. +{roles: {group_id: user_group_ids}}+. The same condition is used to
  # check a single record with +can?+ and to list all records with +accessible_by+.
  # Hashes may be combined with +any_of+, +all_of+ and +none_of+.
  # Return +{}+ to allow all records and +nil+ if the rule does not apply to the user.
  #
  # With a +general+ constraint, an additional condition that every rule for the given actions
  # must fulfill may be defined, independent of the user's permissions.
  #
  # Constraints for +class_side+ actions only depend on the user and return +{}+ or +nil+.
  #
  # Every permission tuple (Role::Permission, Action), including :general,
  # only has one corresponding constraint method. This may be overriden by wagons.
  class Base
    private

    attr_reader :user_context, :permission

    public

    def initialize(user_context, permission)
      @user_context = user_context
      @permission = permission
    end

    class << self
      attr_reader :abilities

      # Define permissions for the given subject_class.
      # An ability class may define mulitple subject classes,
      # but a subject class may only appear in one ability class.
      # See Ability.register as well.
      def on(subject_class, &block)
        @abilities ||= {}
        @abilities[subject_class] ||= []
        @abilities[subject_class] << block
      end

      def subject_classes
        @abilities.keys
      end

      # Available constraint methods in this ability class
      def constraint_methods
        # public methods from base and all subclasses
        ancestors.each_with_object([]) do |current, methods|
          methods.concat(current.public_instance_methods(false))
          break methods if current == AbilityDsl::Base
        end
      end
    end

    # Matches all subjects
    def all
      {}
    end

    # Matches no subjects
    def none
      nil
    end

    # Matches all users
    def everybody
      {}
    end

    # Matches no user
    def nobody
      nil
    end

    def if_admin
      {} if user_context.admin
    end

    def if_any_role
      {} if user.roles.present?
    end

    private

    def any_of(*conditions)
      Condition.any_of(*conditions)
    end

    def all_of(*conditions)
      Condition.all_of(*conditions)
    end

    def none_of(*conditions)
      Condition.none_of(*conditions)
    end

    # Nests a condition under the given path of associations to one record each.
    def nested(*path, condition)
      case condition
      when nil then nil
      when Hash then nest_hash(path, condition)
      when Condition::AnyOf, Condition::AllOf then nest_operands(path, condition)
      else raise ArgumentError, "Cannot nest #{condition.inspect}, use a subquery instead"
      end
    end

    def nest_operands(path, condition)
      operands = condition.operands.map { |o| nested(*path, o) }
      condition.is_a?(Condition::AnyOf) ? any_of(*operands) : all_of(*operands)
    end

    def nest_hash(path, condition)
      return condition if condition.empty?

      path.reverse.inject(condition) { |nested, key| {key => nested} }
    end

    # The ids of the records the user may perform the given action on, as a subquery for
    # a condition value. Building the other ability is deferred until the condition is evaluated.
    def accessible_ids(model_class, action, ability_class = Ability)
      AccessibleIds.new(model_class, action, ability_class, user)
    end

    # lft ranges of the given groups and all groups below, for a condition on Group#lft.
    def below_layers(layer_ids)
      user_context.group_ranges(layer_ids)
    end

    # Conditions on a group to be within the given groups or below, inside the same layer.
    def below_groups(group_ids)
      user_context.local_group_ranges(group_ids).map do |layer_group_id, ranges|
        {layer_group_id: layer_group_id, lft: ranges}
      end
    end

    # Values of the inheritance column matching the given classes. Records of a base class
    # may have no type.
    def sti_names(classes)
      classes.flat_map { |c| (c == c.base_class) ? [nil, c.sti_name] : [c.sti_name] }.uniq
    end

    def role_type?(*role_types)
      contains_any?(role_types, user.roles.collect(&:class))
    end

    def user_group_ids
      user_context.permission_group_ids(permission) || []
    end

    def user_layer_ids
      user_context.permission_layer_ids(permission) || []
    end

    def user_finance_layer_ids
      user_context.permission_layer_ids(:finance)
    end

    def user_see_invisible_layer_ids
      user_context.permission_layer_ids(:see_invisible_from_above)
    end

    # Are any items of the existing list present in the list of required items?
    def contains_any?(required, existing)
      (required & existing).present?
    end

    def user
      user_context.user
    end
  end
end
