class FullTextController < ApplicationController

  skip_authorization_check
  
  helper_method :entries
  
  respond_to :html
  

  def index
    @people = PersonDecorator.decorate(list_entries)
    respond_with(@people)
  end
  
  def query
    
  end

  private
  
  def list_entries
    entries = Person.search(params[:q], 
                            page: params[:page], 
                            order: 'last_name asc, first_name asc, @relevance desc',
                            with: {sphinx_internal_id: accessible_people_ids})
    entries = Person::PreloadGroups.for(entries)
    entries = Person::PreloadPublicAccounts.for(entries)
    entries
  end
  
  def accessible_people
    Person.accessible_by(Ability::Accessibles.new(current_user)).pluck('people.id')
  end
  
  def entries
    @people
  end
end