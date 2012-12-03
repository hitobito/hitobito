class Event::QualificationsController < ApplicationController
    
  before_filter :authorize

  decorates :event, :participants, :participation, :group
  
  helper_method :event, :entries, :participation
  
  def index
    entries
  end
  
  def update
    qualifier.issue
    render 'qualification'
  end
  
  def destroy
    qualifier.revoke
    render 'qualification'
  end
  
  private
   
  def entries
    @participants ||= event.participants.includes(:event)
  end
  
  def qualifier
    Event::Qualifier.new(participation)
  end
  
  def event
    @event ||= group.events.find(params[:event_id])
  end
    
  def group
    @group ||= Group.find(params[:group_id])
  end
  
  def participation
    @participation ||= event.participations.find(params[:id])
  end
  
  def authorize
    authorize!(:qualify, event)
  end
end
