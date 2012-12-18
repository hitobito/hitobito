# encoding: utf-8

class Group::MergeController < ApplicationController

  decorates :group

  before_filter :authorize
  before_filter :mergeable_groups, only: :select
  before_filter :check_params, :check_merge_group, only: :perform

  def select
  end

  def perform
    merge = Group::Merger.new(group, @merge_group, params[:new_group_name])
    if merge.group2_valid?
      merge.merge!
      redirect_to group_path(merge.new_group)
    else
      flash[:alert] = 'Die gewählten Gruppen können nicht fusioniert werden.'
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

  def mergeable_groups
    groups = group.sister_groups
    @mergeable_groups = groups.select {|g| can?(:update, g)}
    if @mergeable_groups.empty? 
      flash[:alert] = 'Es sind keine Gruppen zum Fusionieren vorhanden.'
      redirect_to group_path(group)
    end
  end

  def check_params
    if params[:new_group_name].blank?
      flash[:alert] = 'Name für neue Gruppe muss definiert werden.'
      redirect_to merge_group_path(group)
    elsif params[:merge_group_id].blank?
      flash[:alert] = 'Bitte wähle eine Gruppe mit der fusioniert werden soll.'
      redirect_to merge_group_path(group)
    end
  end

  def check_merge_group
    @merge_group ||= Group.find(params[:merge_group_id])
    if (!can?(:update, @merge_group) || !can?(:update, group))
      flash[:alert] = 'Leider fehlt dir die Berechtigung um diese Gruppen zu fusionieren.'
      redirect_to merge_group_path(group)
    end
  end
  
end
