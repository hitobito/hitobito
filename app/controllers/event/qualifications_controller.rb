class Event::QualificationsController < ApplicationController
    
  before_filter :authorize

  before_filter :entries, only: :index
  
  decorates :event, :participants, :participation
  
  helper_method :event, :entries, :participation
  
  
  def update
    if event.kind_id?
      event.kind.qualification_kinds.each do |q|
        participation.person.qualifications.create(qualification_kind: q, start_at: event.qualification_date)
      end
    end
    render 'qualification'
  end
  
  def destroy
    participation.qualifications.destroy_all
    render 'qualification'
  end
  
  private
   
  def entries
    @participants ||= event.participants
  end
  
  def event
    @event ||= Event.find(params[:event_id])
  end
  
  def participation
    @participation ||= Event::Participation.find(params[:id])
  end
  
  def authorize
    authorize!(:qualify, event)
  end
end