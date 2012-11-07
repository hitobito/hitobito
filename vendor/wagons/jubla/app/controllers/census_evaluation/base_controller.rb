class CensusEvaluation::BaseController < ApplicationController
  
  class_attribute :sub_group_type
  
  before_filter :authorize
  
  decorates :group, :sub_groups
  
  def total
    @sub_groups = sub_groups
    @counts = counts_by_sub_group
    @total = group.census_total(year)
  end
  
  def detail
    @details = group.census_details(year)
  end
  
  private
  
  def sub_groups
    if sub_group_type
      group.descendants.where(type: sub_group_type.sti_name).reorder(:name)
    else
      Group.where('1=0') # none
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
  
  def year
    @year ||= params[:year] || Census.last.year
  end
  
  def authorize
    authorize!(:census, group)
  end
end