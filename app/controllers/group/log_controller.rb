# frozen_string_literal: true

#  Copyright (c) 2022-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::LogController < ApplicationController
  before_action :authorize_action
  prepend_before_action :entry
  attr_reader :entry

  decorates :group, :versions

  def index
    binding.pry

    @versions = PaperTrail::Version
      .from(versions.create_table_alias(versions_union_query, "versions"))
      .distinct
      .includes(:item)
      .reorder("created_at DESC, id DESC")
      .page(params[:page])
  end

  private

  def versions_union_query
    group_versions_cte
      .union(active_people_versions_cte)
      .union(deleted_roles_versions_cte)
  end

  def group_versions_cte_table = Arel::Table.new(:group_versions)

  def group_versions_cte_definition
    versions
      .project(versions[:id])
      .where(versions[:main_type].eq(Group.sti_name))
      .where(versions[:main_id].eq(entry.id))
  end

  def group_versions_cte = Arel::Nodes::As.new(group_versions_cte_definition, group_versions_cte_table)

  def active_people_versions_cte_table = Arel::Table.new(:active_people_versions)

  def active_people_versions_cte_definition
    versions
      .project(versions[:id])
      .where(versions[:main_type].eq(Person.sti_name))
      .join("INNER JOIN (#{active_people_relation.to_sql})").on("versions.main_id = people.id")
  end

  def active_people_versions_cte = Arel::Nodes::As.new(active_people_versions_cte_definition, active_people_versions_cte_table)

  def active_people_relation
    Person
      .accessible_by(PersonFullReadables.new(current_person))
      .joins(:roles)
      .merge(Role.without_archived)
      .where(roles: {group: relevant_groups})
  end

  def deleted_roles_versions_cte_table = Arel::Table.new(:deleted_roles_versions)

  def deleted_roles_versions_cte_definition
    versions
      .project(versions[:id])
      .where(versions[:main_type].eq(Role.sti_name))
      .where(versions[:event].eq("destroy"))
      .join("INNER JOIN (#{deleted_roles_relation.to_sql})").on("versions.item_id = roles.id")
  end

  def deleted_roles_versions_cte = Arel::Nodes::As.new(deleted_roles_versions_cte_definition, deleted_roles_versions_cte_table)

  def relevant_groups
    @relevant_groups ||= group.self_and_descendants
      .where(layer_group_id: group.layer_group_id)
      .filter do |group|
        can?(:log, group)
      end
  end

  def versions
    PaperTrail::Version.arel_table
  end

  def roles
    Role.arel_table
  end

  def authorize_action
    authorize!(:log, entry)
  end

  def entry
    @entry ||= @group ||= Group.find(params[:group_id])
  end

  alias_method :group, :entry
end
