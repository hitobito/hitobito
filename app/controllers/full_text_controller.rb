# encoding: utf-8

class FullTextController < ApplicationController

  skip_authorization_check
  
  helper_method :entries
  
  respond_to :html
  

  def index
    @people = PersonDecorator.decorate(list_people)
    respond_with(@people)
  end
  
  def query
    people = query_people.collect{|i| PersonDecorator.new(i).as_quicksearch }
    groups = query_groups.collect{|i| GroupDecorator.new(i).as_quicksearch }
    
    result = if people.present? && groups.present?
      people + [{label: '—' * 20}] + groups
    else
      people + groups
    end
    render json: result
  end

  private
  
  def list_people
    entries = Person.search(params[:q], 
                            page: params[:page], 
                            order: 'last_name asc, first_name asc, @relevance desc',
                            with: {sphinx_internal_id: accessible_people_ids})
    entries = Person::PreloadGroups.for(entries)
    entries = Person::PreloadPublicAccounts.for(entries)
    entries
  end
  
  def query_people
    Person.search(params[:q],
                  per_page: 10,
                  with: {sphinx_internal_id: accessible_people_ids})
  end
    
  def query_groups
    Group.search(params[:q],
                 per_page: 10,
                 include: :parent)
  end
  
  def accessible_people_ids
    Person.accessible_by(Ability::Accessibles.new(current_user)).pluck('people.id')
  end
  
  def entries
    @people
  end
end