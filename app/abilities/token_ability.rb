#  Copyright (c) 2018-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A token ability is like a normal ability, except it is based on a service token
# and simulates a "dynamic user" for calculating the permissions.
# Also, a service token has a permission (e.g. layer_and_below_full) which is
# applied to the simulated user, and allowed scopes (e.g. :people, :groups, ...)
# which limit the permissions that are actually granted.
class TokenAbility < Ability
  include ApiScopeAbility

  attr_reader :token

  delegate :dynamic_user_ability, to: :token

  def initialize(token)
    return if token.nil?
    @token = token
    super(token.dynamic_user)

    can :register_people, Group, id: registerable_groups if can_register_people?

    # Mailing lists can only be read by normal users with _full permission, see #964.
    # For service tokens however, it would be unintuitive to require write permission
    # for reading mailing lists. So we allow service tokens separately.
    # However, granting read access on sub-layers would enable privilege escalation, so
    # we grant it only on the current layer, even when the token has layer_and_below_*.
    if acceptable?(:mailing_lists)
      can :show, MailingList, group_id: token.layer.groups_in_same_layer.pluck(:id)
    end
  end

  def identifier
    "token-#{token.id}"
  end

  private

  def acceptable_special_case?(subject_class_name, action)
    # Service tokens, unlike normal users, may not use the self registration API outside
    # their permission range (e.g. layer_full or layer_and_below_full). Therefore,
    # we declare this permission as a separate `can` instead of inheriting this permission
    # from the dynamic_user.
    return false if subject_class_name == "Group" && action == :register_people
    super
  end

  def acceptable?(scope) = token.send(:"#{scope}?")

  def write_permission? = token.permission =~ /_full$/

  def can_register_people? = write_permission? && acceptable?(:register_people)

  def registerable_groups
    groups = case token.permission.to_sym
    when :layer_and_below_full
      token.layer.self_and_descendants
    when :layer_full
      token.layer.groups_in_same_layer
    else
      Group.none
    end

    groups.self_registration_active.pluck(:id)
  end
end
