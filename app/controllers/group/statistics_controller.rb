# frozen_string_literal: true

#  Copyright (c) 2022-2022, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::StatisticsController < CrudController
  skip_authorize_resource only: :show
  decorates :group

  def show
    FeatureGate.assert!('groups.statistics')

    authorize!(:show_statistics, entry)

    statistic = Group::Demographic.new(entry)
    @age_groups = statistic.age_groups
    @total_count = statistic.total_count
    @max_relative_count = statistic.max_relative_count
    @group_names = entry.groups_in_same_layer.map(&:to_s)
  end

  def self.model_class
    Group
  end

  private

  def entry
    @entry = @group ||= model_scope.find(params[:group_id])
  end
end
