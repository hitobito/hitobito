class CensusEvaluation::BaseController < ApplicationController
  
  include YearBasedPaging
  
  class_attribute :sub_group_type
  
  before_filter :authorize
  
  decorates :group, :sub_groups
  
  def index
    current_census
    @sub_groups = sub_groups
    @group_counts = counts_by_sub_group
    @total = group.census_total(year)
    @details = group.census_details(year)
  end
  
  private
  
  def sub_groups
    if sub_group_type
      group.descendants.where(type: sub_group_type.sti_name).reorder(:name)
    end
  end
  
  def counts_by_sub_group
    if sub_group_type
      sub_group_field = :"#{sub_group_type.model_name.element}_id"
      group.census_groups(year).inject({}) do |hash, count|
        hash[count.send(sub_group_field)] = count
        hash
      end
    end
  end

  def group
    @group ||= Group.find(params[:id])
  end
  
  def current_census
    @current_census ||= Census.current
  end
  
 
  def default_year
    @default_year ||= current_census.try(:year) || current_year
  end
  
  def current_year
    @current_year ||= Date.today.year
  end
  
  def year_range
    @year_range ||= (year-3)..(year+1)
  end
  
  def authorize
    authorize!(:evaluate_census, group)
  end
end