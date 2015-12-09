# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Status
  # Figures out if an add request was approved or rejected.
  # This checks if the given person exists in the desired body or not.
  class Base

    attr_reader :person_id, :body_id

    def initialize(person_id, body_id)
      @person_id = person_id
      @body_id = body_id
    end

    def pending
      @pending ||=
        Person::AddRequest.where(type: request_type,
                                 person_id: person_id,
                                 body_id: body_id).
                           first
    end

    def pending?
      pending.present?
    end

    def person
      @person ||= Person.find(person_id)
    end

    def created?
      fail(NotImplementedError)
    end

    def approved_message
      'TOOD: request type specific approved message'
    end

    def rejected_message
      'TOOD: request type specific rejected message'
    end

    private

    def request_type
      "Person::AddRequest::#{self.class.name.demodulize}"
    end

  end
end
