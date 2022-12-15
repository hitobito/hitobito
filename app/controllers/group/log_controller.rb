# frozen_string_literal: true

#  Copyright (c) 2022-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::LogController < ApplicationController

  before_action :authorize_action
  prepend_before_action :entry

  decorates :group

  def index
    # Pseudocode of doom
    # relevant_people_ids = filtered(relevant_groups).flat_map do |group|
    #   PersonReadables.new(current_user, group).accessible_people.map do |person|
    #     person.id
    #   end
    # end

    # PaperTrail::Version.where(main_type: Person.sti_name, main_id: relevant_people_ids).order(created_at: :desc).page(page)


  end

  private

  def authorize_action
    authorize!(:"#{action_name}_logs", entry)
  end

  def gate_feature
    FeatureGate.assert!('groups.statistics')
  end

  def entry
    @entry = @group ||= Group.find(params[:group_id])
  end

end
