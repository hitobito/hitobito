# frozen_string_literal: true

#  Copyright (c) 2022-2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::StatisticsController < ApplicationController
  include Rememberable

  helper_method :statistic

  before_action :authorize_action
  before_action :gate_feature

  self.remember_params = [:key]

  decorates :group
  prepend_before_action :handle_remember_params, only: [:index, :show]

  def index
    if available_statistics.empty?
      redirect_with_alert(:none_available)
    else
      redirect_to group_statistic_path(group, remembered_or_default_key)
    end
  end

  def show
    return redirect_with_alert(:not_found) unless statistic_class
    return redirect_with_alert(:not_available) unless statistic_class.available_for?(group)

    statistic.valid? # run validations so errors are available in the view
  end

  def statistic_key
    params.require(:key).to_sym
  end

  private

  def available_statistics
    @available_statistics ||= Group::Statistics::Registry.available_for(group)
  end

  def remembered_or_default_key
    keys = available_statistics.map(&:key)
    requested = params[:key]&.to_sym
    keys.include?(requested) ? requested : keys.first
  end

  def statistic_class
    @statistic_class ||= Group::Statistics::Registry.find_by_key(statistic_key)
  end

  def statistic
    @statistic ||= statistic_class.new(group, params)
  end

  def authorize_action
    authorize!(:show_statistics, group)
  end

  def gate_feature
    FeatureGate.assert!("groups.statistics")
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def redirect_with_alert(key)
    redirect_to group_path(group), alert: t(".#{key}")
  end

  def remember_key
    @remember_key ||= self.class.name.underscore
  end
end
