# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::MergeController < ApplicationController

  decorates :group

  before_action :authorize
  before_action :check_params, :check_merge_group, only: :perform

  def select
    candidates
  end

  def perform
    merger = Group::Merger.new(group, @merge_group, params[:merger][:new_group_name])
    if merger.group2_valid? && merger.merge!
      flash[:notice] = translate(:success, new_group_name: merger.new_group_name)
      redirect_to group_path(merger.new_group)
    else
      flash[:alert] = merger.errors ? merger.errors.join('<br/>').html_safe : translate(:failure)
      redirect_to merge_group_path(group)
    end
  end

  private

  def group
    @group ||= Group.find(params[:id])
  end

  def authorize
    authorize!(:edit, group)
  end

  def candidates
    groups = group.sister_groups
    @candidates = groups.select { |g| can?(:update, g) }
    if @candidates.empty?
      flash[:alert] = translate(:no_candidates)
      redirect_to group_path(group)
    end
  end

  def check_params
    if params[:merger][:new_group_name].blank?
      flash[:alert] = translate(:group_name_missing)
      redirect_to merge_group_path(group)
    elsif params[:merger][:merge_group_id].blank?
      flash[:alert] = translate(:no_group_selected)
      redirect_to merge_group_path(group)
    end
  end

  def check_merge_group
    @merge_group ||= Group.find(params[:merger][:merge_group_id])

    if !can?(:update, @merge_group) || !can?(:update, group)
      flash[:alert] = translate(:not_allowed)
      redirect_to merge_group_path(group)
    end
  end

end
