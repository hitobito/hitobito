class PopulationController < ApplicationController
  
  before_filter :authorize

  decorates :groups, :people, :group
  
  
  def index
    @groups = load_groups
    @people_by_group = load_people_by_group
    @people_data_complete = people_data_complete?
  end

  private
  
  def load_people(groups)
    Person.joins(:roles).
           where(roles: {group_id: groups.collect(&:id)}).
           affiliate(false).
           preload_groups.
           uniq.
           order_by_role.
           order_by_name
  end

  def flock
    @group ||= Group::Flock.find(params[:id])
  end

  def load_groups
    flock.groups_in_same_layer.order_by_type(flock)
  end

  def load_people_by_group
    @groups.each_with_object({}) do |group, hash|
      hash[group] = PersonDecorator.decorate(load_people([group]))
    end
  end

  def people_data_complete?
    @people_by_group.values.flatten.all? do |p|
      p.birthday.present? && p.gender.present?
    end
  end

  def authorize
    authorize!(:approve_population, flock)
  end
  
end
