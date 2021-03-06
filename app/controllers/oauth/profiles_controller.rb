# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


module Oauth
  class ProfilesController < ActionController::Base
    before_action do
      doorkeeper_authorize! :with_roles, :email, :name
    end

    def show
      if scope.blank? || doorkeeper_token.acceptable?(scope)
        render json: email_attrs.merge(scope_attrs || {})
      else
        render json: { error: "invalid scope: #{scope}" }, status: 403
      end
    end

    private

    def scope_attrs
      case scope
      when /name/ then
        person.attributes.slice('first_name', 'last_name', 'nickname')
      when /with_roles/ then
        public_attrs_with_roles
      when /events/ then
        event_attrs
      end
    end

    def scope
      request.headers['X-Scope'].to_s
    end

    def person
      @person ||= Person.find(doorkeeper_token.resource_owner_id)
    end

    def public_attrs_with_roles
      roles = person.roles.includes(:group).collect do |role|
        {
          group_id: role.group_id,
          group_name: role.group.name,
          role_name: role.class.model_name.human,
          permissions: role.class.permissions
        }
      end
      person.attributes.slice(*Person::PUBLIC_ATTRS.collect(&:to_s)).merge(roles: roles)
    end

    def email_attrs
      { id: person.id, email: person.email }
    end

    def event_attrs
      events = person.events.collect do |event|
        {
          event_id: event.id,
          event_name: event.name,
          event_description: event.description,
          event_motto: event.motto,
          event_location: event.location,
          event_type: event.type,
          event_number: event.number,
          event_dates: event_dates(event),
          event_kind: event.course_kind? ? event.kind.label : nil,
          roles: event_roles(person.event_participations.where(event_id: event.id)),
        }
      end
      { events: events }
    end

    def event_dates(event)
      event.dates.collect do |date|
        {
          label: date.label,
          start_at: date.start_at,
          finish_at: date.finish_at
        }
      end
    end
    
    def event_roles(participations)
      participations.collect do |participation|
        participation.roles.collect do |role|
          {
            type: role.type,
            label: role.label
          }
        end
      end.flatten
    end
  end
end
