# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::MoveController < ApplicationController

  decorates :group
  helper_method :group

  before_action :group
  before_action :authorize

  def select
    candidates
  end

  def perform
    if target && mover.candidates.include?(target)
      authorize!(:create, target)

      success = mover.perform(target)
      build_flash_messages(success)
      redirect_to(group)
    else
      flash[:alert] = translate(:choose_group)
      redirect_to move_group_path(group)
    end
  end

  private

  def group
    @group ||= Group.find(params[:id])
  end

  def candidates
    @candidates = mover.candidates.select { |candidate| can?(:create, candidate) }.
                                   group_by { |candidate| candidate.class.label }
    @candidates.values.each { |groups| groups.sort_by(&:name) }

    if @candidates.empty?
      flash[:alert] = translate(:failure)
      redirect_to group_path(group)
    end
  end

  def mover
    @mover ||= Group::Mover.new(group)
  end

  def target
    @target ||= (params[:move] && params[:move][:target_group_id]) &&
                Group.find(params[:move][:target_group_id])
  end

  def build_flash_messages(success)
    if success
      flash[:notice] = translate(:success, group: group, target: target)
    else
      flash[:alert] = group.errors.full_messages.join(', ')
    end
  end

  def authorize
    authorize!(:update, group)
  end

end
