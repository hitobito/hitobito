class Group::MoveController < ApplicationController
  decorates :group
  #helper_method :group
  before_filter :group
  before_filter :candidates, only: :select

  def select
    authorize!(:update, group)
  end

  def perform
    authorize!(:update, group)
    authorize!(:create, target)

    if target && mover.perform(target)
      flash[:notice] = "#{group} wurde nach #{target} verschoben."
    end
    redirect_to(group)
  end

  private
  def group
    @group ||= Group.find(params[:id])
  end

  def candidates
    @candidates = mover.candidates.select { |candidate| can?(:create, candidate) }.
    group_by { |candidate| candidate.class.model_name.human }

    if @candidates.empty? 
      flash[:alert] = 'Diese Gruppe kann leider nicht verschoben werden.'
      redirect_to group_path(group)
    end

  end

  def mover
    @mover ||= Group::Mover.new(group)
  end

  def target
    @target ||= (params[:move] && params[:move][:target_group_id]) && Group.find(params[:move][:target_group_id])
  end


end
