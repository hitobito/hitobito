# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::HistoryController < ApplicationController

  before_action :authorize_action

  decorates :group, :person

  def index
    @roles = fetch_roles(:without_deleted, :without_future)
    @future_roles = fetch_roles(:future)
    @inactive_roles = fetch_roles(:inactive)
    @participations_by_event_type = participations_by_event_type
    @qualifications = Qualifications::List.new(entry).qualifications
  end

  private

  def roles_scope
    Person::PreloadGroups.for([entry]).first.roles.includes(group: :parent)
  end

  def fetch_roles(*scopes)
    scopes
      .inject(roles_scope) { |current, additional| current.send(additional) }
      .sort_by { |r| GroupDecorator.new(r.group).name_with_layer }
  end

  def fetch_participations
    Person::EventQueries.new(entry).alltime_participations
  end

  def participations_by_event_type
    fetch_participations.
      group_by { |p| p.event.class.label_plural }.
      each { |_kind, entries| entries.collect! { |e| Event::ParticipationDecorator.new(e) } }
  end

  def entry
    @person ||= fetch_person
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    authorize!(:history, entry)
  end

end
