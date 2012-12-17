# encoding: utf-8

class Group::MergeController < ApplicationController

  decorates :group

  before_filter :authorize, :mergeable_groups
  before_filter :check_params, :check_merge_group, only: :perform

  def select
  end

  def perform
    merge = Group::Merger.new(group, @merge_group, params[:new_group_name])
    redirect_to group_path(merge.new_group)
  end

  private

  def group
    @group ||= Group.find(params[:id])
  end

  def authorize
    authorize!(:merge, group)
  end

  def mergeable_groups
    groups = group.groups_with_same_parent_and_type
    @mergeable_groups = groups.collect {|g| g if can?(:update, g)}
  end

  def check_params
    if params[:new_group_name].blank?
      flash[:alert] = 'Name für neue Gruppe muss definiert werden.'
      redirect_to merge_group_path(group)
    elsif params[:merge_group_id].blank?
      flash[:alert] = 'Bitte wähle eine Gruppe die fusioniert werden soll.'
      redirect_to merge_group_path(group)
    end
  end

  def check_merge_group
    @merge_group ||= Group.find(params[:merge_group_id])
    if !can?(:update, @merge_group)
      flash[:alert] = 'Leider fehlt dir die Berechtigung diese Gruppe zu fusionieren.'
      redirect_to merge_group_path(group)
    end
  end
  
end
