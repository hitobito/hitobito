#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  class PassEligibility
    attr_reader :definition

    def initialize(definition)
      @definition = definition
    end

    # --- Instance methods: Definition → People ---

    # All people eligible for this definition.
    # Joins through pass_grants → grantor group's nested-set bounds → role types.
    def people
      grants = group_grants_with_types
      return Person.none if grants.empty?

      conditions = grants.map { |lft, rgt, rt| role_in_subtree_condition(rt, lft, rgt) }

      Person.joins(roles: :group)
        .where(roles: {archived_at: nil})
        .where(conditions.join(" OR "))
        .distinct
    end

    # Is this person eligible for this definition?
    def member?(person)
      matching_roles(person).exists?
    end

    # The person's active, non-archived roles that match this definition.
    # Uses the default scope (start_on/end_on) plus without_archived,
    # since the default scope does NOT filter on archived_at.
    def matching_roles(person)
      grants = group_grants_with_types
      return person.roles.none if grants.empty?

      conditions = grants.map { |lft, rgt, rt| role_in_subtree_condition(rt, lft, rgt) }

      person.roles
        .without_archived
        .joins(:group)
        .where(conditions.join(" OR "))
    end

    # Like matching_roles but includes ended AND archived roles.
    # Uses with_inactive to bypass the start_on/end_on default scope.
    # Archived roles count as "ended at archived_at" — the pass expires,
    # it is NOT revoked. Only hard-deleted roles (absent from DB) lead
    # to revocation.
    def matching_roles_including_ended(person)
      grants = group_grants_with_types
      return person.roles.none if grants.empty?

      conditions = grants.map { |lft, rgt, rt| role_in_subtree_condition(rt, lft, rgt) }

      person.roles.with_inactive
        .joins(:group)
        .where(conditions.join(" OR "))
    end

    # --- Class methods: Person → Definitions ---

    # All PassDefinitions a person is eligible for.
    # Future: add event_definitions_for, qualification_definitions_for (WP 13).
    def self.definitions_for(person)
      group_definitions_for(person)
    end

    # Group-role-based definitions. Joins through pass_grants:
    # "grant's grantor group encompasses the person's role-group"
    def self.group_definitions_for(person)
      roles_with_groups = person.roles.active.joins(:group)
        .pluck(:type, "groups.lft", "groups.rgt")
      return PassDefinition.none if roles_with_groups.empty?

      conditions = roles_with_groups.map do |role_type, lft, rgt|
        sanitized_type = ActiveRecord::Base.connection.quote(role_type)
        "(related_role_types.role_type = #{sanitized_type}" \
          " AND grantor_groups.lft <= #{lft.to_i} AND grantor_groups.rgt >= #{rgt.to_i})"
      end

      PassDefinition
        .joins(pass_grants: :related_role_types)
        .joins("JOIN groups AS grantor_groups ON grantor_groups.id = pass_grants.grantor_id" \
               " AND pass_grants.grantor_type = 'Group'")
        .where(conditions.join(" OR "))
        .distinct
    end

    # Find PassMemberships affected by a role change (for Role callbacks, WP 4b).
    # Joins through pass_grants to find grants whose grantor encompasses the role's group.
    def self.affected_pass_memberships(person, role:)
      person.pass_memberships
        .joins(pass_definition: {pass_grants: :related_role_types})
        .joins("JOIN groups AS grantor_groups ON grantor_groups.id = pass_grants.grantor_id" \
               " AND pass_grants.grantor_type = 'Group'")
        .where(related_role_types: {role_type: role.type})
        .where("grantor_groups.lft <= :lft AND grantor_groups.rgt >= :rgt",
          lft: role.group.lft, rgt: role.group.rgt)
    end

    private

    def group_grants_with_types
      @group_grants_with_types ||= definition.pass_grants
        .where(grantor_type: "Group")
        .joins(:related_role_types)
        .joins("JOIN groups ON groups.id = pass_grants.grantor_id")
        .pluck("groups.lft", "groups.rgt", "related_role_types.role_type")
    end

    def role_in_subtree_condition(role_type, lft, rgt)
      sanitized_type = ActiveRecord::Base.connection.quote(role_type)
      "(roles.type = #{sanitized_type}" \
        " AND groups.lft >= #{lft.to_i} AND groups.rgt <= #{rgt.to_i})"
    end
  end
end
