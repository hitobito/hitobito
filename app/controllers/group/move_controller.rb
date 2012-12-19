class Group::MoveController < ApplicationController
  decorates :group
  helper_method :group
  before_filter :group

  def select
    authorize!(:update, group)

    @candidates = candidates
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
    mover.candidates.select { |candidate| can?(:create, candidate) }.
    group_by { |candidate| candidate.class.model_name.human }
  end

  def mover
    @mover ||= Group::Mover.new(group)
  end

  def target
    @target ||= (params[:mover] && params[:mover][:group]) && Group.find(params[:mover][:group])
  end


end
