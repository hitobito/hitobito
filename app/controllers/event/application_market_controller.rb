# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ApplicationMarketController < ApplicationController

  before_action :authorize

  decorates :event, :participants, :participation, :group

  helper_method :event

  def index
    @participants = load_participants
    @applications = load_applications
  end

  def add_participant
    if assigner.createable?
      assigner.create_role
    else
      render 'participation_exists_error'
    end
  end

  def remove_participant
    assigner.remove_role
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
    event.participations_for(event.participant_type).includes(:application)
  end

  def load_applications
    applications = Event::Participation.
                       joins(:event).
                       includes(:application, :person).
                       references(:application).
                       where(filter_applications).
                       merge(Event::Participation.pending).
                       uniq
    sort_applications(applications)
    Event::ParticipationDecorator.decorate_collection(applications)
  end

  def sort_applications(applications)
    # do not include nil values in arrays returned by #sort_by
    applications.sort_by! do |p|
      [p.application.priority(event) || 99,
       p.person.last_name || '',
       p.person.first_name || '']
    end
  end

  def filter_applications
    if params[:prio].nil? && params[:waiting_list].nil?
      params[:prio] = %w(1 2 3)  # default filter
    end

    conditions, args = [], []
    filter_by_prio(conditions, args) if params[:prio]
    filter_by_waiting_list(conditions, args) if params[:waiting_list]

    [conditions.join(' OR '), *args] if conditions.present?
  end

  def filter_by_prio(conditions, args)
    ([1, 2, 3] & params[:prio].collect(&:to_i)).each do |i|
      conditions << "event_applications.priority_#{i}_id = ?"
      args << event.id
    end
  end

  def filter_by_waiting_list(conditions, args)
    conditions << '(event_applications.waiting_list = ? AND events.kind_id = ?)'
    args << true << event.kind_id
  end

  def assigner
    @assigner ||= Event::ParticipantAssigner.new(event, participation)
  end

  def event
    @event ||= group.events.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
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
