class PopulationController < ApplicationController
  
  before_filter :authorize

  decorates :groups, :people, :group
  
  
  def index
    @groups = flock.groups_in_same_layer.order_by_type(flock)
    @people = load_people(@groups)
    @groups_people = load_groups_people
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

  def load_groups_people
    groups_people = {}
    load_groups.each do |group|
      groups_people.merge!({group.id => PersonDecorator.decorate(load_people([group]))})
    end
    groups_people
  end

  def people_data_complete?
    @people.each do |p|
      return false if p.birthday.blank?
      return false if p.gender.blank?
    end
    true
  end

  def authorize
    authorize!(:approve_population, flock)
  end
  
end
