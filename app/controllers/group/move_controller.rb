# encoding: utf-8
class Group::MoveController < ApplicationController

  decorates :group
  helper_method :group

  before_filter :group
  before_filter :authorize

  def select
    candidates
  end

  def perform
    if target && mover.candidates.include?(target)
      authorize!(:create, target)

      if mover.perform(target)
        flash[:notice] = "#{group} wurde nach #{target} verschoben."
      else
        flash[:alert] = group.errors.full_messages.join(", ")
      end
      redirect_to(group)
    else
      flash[:alert] = 'Bitte wähle eine Gruppe aus.'
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
    @candidates.each {|type, groups| groups.sort_by(&:name) }

    if @candidates.empty?
      flash[:alert] = 'Diese Gruppe kann nicht verschoben werden oder ' +
                      'Du verfügst nicht über die nötigen Berechtigungen.'
      redirect_to group_path(group)
    end
  end

  def mover
    @mover ||= Group::Mover.new(group)
  end

  def target
    @target ||= (params[:move] && params[:move][:target_group_id]) && Group.find(params[:move][:target_group_id])
  end

  def authorize
    authorize!(:update, group)
  end

end
