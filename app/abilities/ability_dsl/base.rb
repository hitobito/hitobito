# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AbilityDsl
  # Base class for defining abilities.
  # Abilities are defined for models, usually only for one per ability class.
  # Eg.
  #  on(Person) do
  #    class_side(:index).everybody
  #
  #    permission(:group_read).may(:show).in_same_group
  #    permission(:layer_and_below_full).may(:update, :destroy).in_same_layer_or_below
  #  end
  #
  # All permissions in the given block apply for a Person instance.
  # Each permission then is defined for one Role::Permission, several actions and
  # one arbitrary constraint.
  # This constraint must exist as an instance method in the same class and return
  # true if the current Person instance applies. The constraint method should have
  # a speaking name that describes its complete purpose.
  #
  # With a +general+ constraint an additional requirement for certain actions
  # may be defined, indifferent of the user's permissions.
  #
  # To define abilities for class side actions (if no subject instance is passed to +can?+),
  # the +class_side+ method with the corresponding actions has to be used.
  # The following constraint methods must also be defined as instance methods, but there
  # will be no subject and no permission instance variables available. Therefore,
  # certain helper methods like +permission_in_group?+ or permission_in_layers?+ must not
  # be used.
  #
  # Every permission tuple (Role::Permission, Action), including :general,
  # only has one corresponding constraint method. This may be overriden by wagons.
  #
  # BEWARE: The constraint methods only apply if you pass an instance to the #can?
  # method. If you pass a class, no constraints will be checked at all!
  class Base

    private

    attr_reader :user_context, :subject, :permission

    public

    def initialize(user_context, subject, permission)
      @user_context = user_context
      @subject = subject
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
      true
    end

    # Matches no subjects
    def none
      false
    end

    # Matches all users
    def everybody
      true
    end

    # Matches no user
    def nobody
      false
    end

    def if_admin
      user_context.all_permissions.include?(:admin)
    end

    private

    # Check whether the permission for which the check is made is defined in the given group_id.
    def permission_in_group?(group_id)
      user_groups.include?(group_id)
    end

    # Check whether the permission for which the check is made is defined in the given group_ids.
    def permission_in_groups?(group_ids)
      contains_any?(user_groups, group_ids)
    end

    # Check whether the layer permission for which the check is made
    # is defined in the given layer_id. Other permissions always return false,
    # even if they are defined in the given layer id.
    def permission_in_layer?(layer_id)
      user_layers.include?(layer_id)
    end

    # Check whether the layer permission for which the check is made
    # is defined in the given layer_ids. Other permissions always return false,
    # even if they are defined in a given layer id.
    def permission_in_layers?(layer_ids)
      contains_any?(user_layers, layer_ids)
    end

    def user_groups
      @user_groups ||=
        case permission
        when :group_full then user_context.groups_group_full
        when :group_read then user_context.groups_group_read
        when :layer_full then user_context.groups_layer_full
        when :layer_read then user_context.groups_layer_read
        when :layer_and_below_full then user_context.groups_layer_and_below_full
        when :layer_and_below_read then user_context.groups_layer_and_below_read
        else []
        end
    end

    def user_layers
      @user_layers ||=
        case permission
        when :layer_full then user_context.layers_full
        when :layer_read then user_context.layers_read
        when :layer_and_below_full then user_context.layers_and_below_full
        when :layer_and_below_read then user_context.layers_and_below_read
        else []
        end
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
