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
    @versions = PaperTrail::Version.where(id: people_versions)
      .or(PaperTrail::Version.where(id: group_versions))
      .left_joins(:role)
      .includes(:item)
      .reorder("created_at DESC, id DESC")
      .page(params[:page])
  end

  private

  def group_versions
    @group_versions ||= PaperTrail::Version.distinct
      .where(main_type: Group.sti_name)
      .where(main_id: entry.id)
  end

  def people_versions
    @people_versions ||= PaperTrail::Version.distinct
      .where(version_conditions)
  end

  def version_conditions
    versions[:main_type].eq(Person.sti_name).and(
      versions[:main_id].in(Arel::Nodes::SqlLiteral.new(people_scope.to_sql))
    )
  end

  def people_scope
    @active_people ||= Person
      .accessible_by(PersonFullReadables.new(current_person))
      .unscope(:select)
      .select(:id)
      .joins(:roles_unscoped)
      .merge(Role.without_archived)
      .where(roles: {group: relevant_groups})
  end

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
