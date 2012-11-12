# encoding: utf-8
class MemberCountsController < ApplicationController

  before_filter :authorize
  
  decorates :group
  
  
  def edit
    member_counts
  end
  
  def update
    counts = member_counts.update(params[:member_count].keys, params[:member_count].values)
    with_errors = counts.select { |c| c.errors.present? }
    if with_errors.blank?
      flash[:notice] = "Die Mitgliederzahlen wurden erfolgreich gespeichert"
      redirect_to census_flock_group_path(flock, year: year)
    else
      messages = with_errors.collect{|e| "#{e.born_in}: #{e.errors.full_messages.join(", ")}" }.join("; ")
      flash.now[:alert] = "Nicht alle Jahrgänge konnten gespeichert werden. Bitte überprüfen Sie Ihre Angaben. (#{messages})"
      render "edit"
    end
  end

  def create
    
  end
  
  private
  
  def member_counts
    @member_counts ||= flock.member_counts.where(year: year).order(:born_in)
  end
  
  def flock
    @group ||= Group::Flock.find(params[:group_id])
  end
  
  def year
    @year ||= params[:year] ? params[:year].to_i : raise(ActiveRecord::RecordNotFound, 'year required')
  end
  
  def authorize
    authorize!(:update_member_counts, flock)
  end
  
end