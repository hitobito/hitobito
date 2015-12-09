# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Creator
  class Base

    attr_reader :entity, :ability

    def initialize(entity, ability)
      @entity = entity
      @ability = ability
    end

    def required?
      person_layer &&
        person_layer.require_person_add_requests? &&
        ability.cannot?(:add_without_request, request) &&
        entity.valid?
    end

    def create_request
      success = required? && request.save
      Person::SendAddRequestJob.new(request).enqueue! if success
      success
    end

    def requester
      ability.user
    end

    def request
      @request ||= request_class.new(request_attrs)
    end

    def person_layer
      person.primary_group.try(:layer_group)
    end

    def request_attrs
      { person: person,
        requester: requester,
        body: body }
    end

    def body
      fail(NotImplementedError)
    end

    def person
      fail(NotImplementedError)
    end

    def success_message
      fail(NotImplementedError)
    end

    def error_message
      request.errors.full_messages.join(', ')
    end

    def request_class
      "Person::AddRequest::#{self.class.name.demodulize}".constantize
    end

  end
end
