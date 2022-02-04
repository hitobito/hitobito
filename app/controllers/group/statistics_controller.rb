# frozen_string_literal: true

#  Copyright (c) 2022-2022, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::StatisticsController < ApplicationController

  before_action :authorize_action
  before_action :gate_feature
  before_action :redirect_to_layer
  prepend_before_action :entry

  decorates :group

  def show
    statistic = Group::Demographic.new(entry)

    @age_groups = statistic.age_groups
    @total_count = statistic.total_count
    @max_relative_count = statistic.max_relative_count
    @group_names = entry.groups_in_same_layer.map(&:to_s)
  end

  private

  def authorize_action
    authorize!(:"#{action_name}_statistics", entry)
  end

  def gate_feature
    FeatureGate.assert!('groups.statistics')
  end

  def redirect_to_layer
    unless entry.layer?
      redirect_to group_statistics_path(entry.layer_group_id)
    end
  end

  def entry
    @entry = @group ||= Group.find(params[:group_id])
  end

end
