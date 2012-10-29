class Event::ApplicationMarketController < ApplicationController
  
  before_filter :authorize
  
  decorates :event, :participants, :participation
  
  helper_method :event
  
  def index
    load_participants
    load_applications
  end
  
  def add_participant
    if other_participation_exists?
      render 'participation_exists_error'
    else
      participation.create_participant_role(event)
      event.reload
    end
  end
  
  def remove_participant
    participation.remove_participant_role
    event.reload
  end
  
  def put_on_waiting_list
    application.update_column(:waiting_list, true)
    render 'waiting_list'
  end
  
  def remove_from_waiting_list
    application.update_column(:waiting_list, false)
    render 'waiting_list'
  end
  
  private
  
  def load_participants
    @participants = event.participations.joins(:roles).
                                         where(event_roles: {type: event.class.participant_type.sti_name}).
                                         includes(:application, :person).
                                         merge(Person.order_by_name).
                                         uniq
  end
  
  def load_applications
    @applications = Event::ParticipationDecorator.decorate(
          Event::Participation.
                       joins(:event).
                       includes(:application, :person).
                       where(filter_applications).
                       merge(Event::Participation.pending).
                       uniq.
                       sort_by {|p| [p.application.priority(event) || 99, p.person.last_name, p.person.first_name] })
  end
  
  def filter_applications
    if params[:prio].nil? && params[:waiting_list].nil?
      params[:prio] = %w(1 2 3)  # default filter
    end
    
    conditions = []
    args = []
    if params[:prio]
      ([1,2,3] & params[:prio].collect(&:to_i)).each do |i|
        conditions << "event_applications.priority_#{i}_id = ?"
        args << event.id
      end
    end
    if params[:waiting_list]
      conditions << "(event_applications.waiting_list = ? AND events.kind_id = ?)"
      args << true << event.kind_id
    end
    
    if conditions.present?
      [conditions.join(" OR "), *args]
    end
  end
  
  def other_participation_exists?
    participation.event_id != event.id && event.participations.where(person_id: participation.person_id).exists?
  end
  
  def event
    @event ||= Event.find(params[:event_id])
  end
  
  def participation
    @participation ||= Event::Participation.find(params[:id])
  end
  
  def application
    participation.application
  end
 
  def authorize
    authorize!(:application_market, event)
  end
end