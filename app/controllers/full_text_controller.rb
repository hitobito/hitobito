class FullTextController < ApplicationController

  skip_authorization_check
  
  helper_method :entries
  
  respond_to :html
  

  def index
    @people = PersonDecorator.decorate(list_entries)
      
      #company_ids = Company.accessible_by(current_ability).collect &:id
      #@companies  = Company.search params[:search],
      #  :include    => :order,
      #  :match_mode => :extended,
      #  :page       => params[:page],
      #  :with       => {:sphinx_internal_id => company_ids}
      
    respond_with(@people)
  end
  
  def query
    
  end  

  private
  
  def list_entries
    entries = Person.search(params[:q], page: params[:page], order: 'last_name asc, first_name asc, @relevance desc')
    entries = Person::PreloadGroups.for(entries)
    entries = Person::PreloadPublicAccounts.for(entries)
    entries
  end
  
  def entries
    @people
  end
end