# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::MergeController < ApplicationController

  decorates :group

  before_filter :authorize
  before_filter :check_params, :check_merge_group, only: :perform

  def select
    candidates
  end

  def perform
    merger = Group::Merger.new(group, @merge_group, params[:merger][:new_group_name])
    if merger.group2_valid?
      if merger.merge!
        flash[:notice] = "Die gewählten Gruppen wurden zur neuen Gruppe #{merger.new_group_name} fusioniert."
        redirect_to group_path(merger.new_group)
      else
        flash[:alert] = merger.errors.join("<br/>").html_safe
        redirect_to merge_group_path(group)
      end
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

  def candidates
    groups = group.sister_groups
    @candidates = groups.select {|g| can?(:update, g) }
    if @candidates.empty?
      flash[:alert] = 'Es sind keine gleichen Gruppen zum Fusionieren vorhanden oder ' +
                      'Du verfügst dort nicht über die nötigen Berechtigungen.'
      redirect_to group_path(group)
    end
  end

  def check_params
    if params[:merger][:new_group_name].blank?
      flash[:alert] = 'Name für neue Gruppe muss definiert werden.'
      redirect_to merge_group_path(group)
    elsif params[:merger][:merge_group_id].blank?
      flash[:alert] = 'Bitte wähle eine Gruppe mit der fusioniert werden soll.'
      redirect_to merge_group_path(group)
    end
  end

  def check_merge_group
    @merge_group ||= Group.find(params[:merger][:merge_group_id])

    if !can?(:update, @merge_group) || !can?(:update, group)
      flash[:alert] = 'Leider fehlt dir die Berechtigung um diese Gruppen zu fusionieren.'
      redirect_to merge_group_path(group)
    end
  end

end
