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
                                   .reorder('created_at DESC, id DESC')
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
    base_conditions.and(
      active_person_conditions.or(deleted_role_conditions)
    )
  end

  def base_conditions
    versions[:main_type].eq(Person.sti_name)
  end

  def active_person_conditions
    versions[:main_id].in(Arel::Nodes::SqlLiteral.new(active_people.to_sql))
  end

  def deleted_role_conditions
    versions[:item_type].eq(Role.sti_name).
      and(versions[:event].eq('destroy')).
      and(roles[:group_id].in(relevant_groups.map(&:id))).
      and(roles[:deleted_at].lteq(Time.now))
  end

  def active_people
    @active_people ||= Person.
      accessible_by(PersonFullReadables.new(current_person)).
      unscope(:select).
      select(:id).
      joins(:roles).
      merge(Role.without_archived).
      where(roles: { group: relevant_groups })
  end

  def relevant_groups
    @relevant_groups ||= group.self_and_descendants.
      where(layer_group_id: group.layer_group_id).
      filter do |group|
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

  alias group entry
end
