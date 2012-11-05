class Event::ApplicationsController < ApplicationController
  
  before_filter :application
  authorize_resource
      
  def approve
    toggle_approval(true, 'freigegeben')
  end
  
  def reject
    toggle_approval(false, 'abgelehnt')
  end
  
  private
  
  def toggle_approval(approved, verb)
    application.approved = approved
    application.rejected = !approved
    application.save!
    flash[:notice] = "Die Anmeldung wurde #{verb}"
    redirect_to event_participation_path(participation.event_id, participation)
  end
  
  def event
    @event ||= Event.find(params[:event_id])
  end
  
  def application
    @application ||= Event::Application.find(params[:id])
  end
  
  def participation
    application.participation
  end
end