# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
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
    if merger.group2_valid? && merger.merge!
      respond_success
    else
      respond_failure
    end
  end

  private

  def respond_success
    flash[:notice] = translate(:success, new_group_name: merger.new_group_name)
    flash[:alert]  = translate(:invoice_config_not_merged)
    redirect_to group_path(merger.new_group)
  end

  def respond_failure
    flash[:alert] = merger.errors ? merger.errors.to_sentence : translate(:failure)
    redirect_to merge_group_path(group)
  end

  def group
    @group ||= Group.find(params[:id])
  end

  def merger
    @merger ||= Group::Merger.new(group, @merge_group, params[:merger][:new_group_name])
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

  def authorize
    authorize!(:edit, group)
  end

end
