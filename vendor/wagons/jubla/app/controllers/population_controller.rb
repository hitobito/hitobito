class PopulationController < ApplicationController
  
  before_filter :authorize
  
  decorates :groups, :people, :group
  
  
  def index
    @current_census = Census.current
    @approvable = @current_census && !MemberCounter.new(@current_census.year, flock).exists?
    @groups = flock.groups_in_same_layer.order_by_type(flock)
    @people = load_people
  end

  private
  
  def load_people
    Person.includes(:roles).
           where(roles: {group_id: @groups.collect(&:id)}).
           affiliate(false).
           order_by_role.
           order_by_name
  end
  
  def flock
    @group ||= Group::Flock.find(params[:id])
  end
  
  def authorize
    authorize!(:approve_population, flock)
  end
  
end