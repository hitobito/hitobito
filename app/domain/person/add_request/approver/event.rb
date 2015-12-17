# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Approver
  class Event < Base

    private

    # TODO move that out to domain object shared with controllers?
    # set state assigned for youth wagon
    def build_entity
      participation = event.participations.where(person_id: request.person_id).first_or_initialize
      if participation.new_record?
        participation.init_answers
        participation.active = true
        if event.supports_applications
          appl = participation.build_application
          appl.priority_1 = event
        end
      end
      if participation.roles.none? { |r| r.class.sti_name == request.role_type }
        role = participation.roles.build(type: role_type.sti_name)
        role.participation = participation
      end
      participation
    end

    def role_type
      @role_type ||= event.class.find_role_type!(request.role_type)
    end

    def event
      request.body
    end

  end
end
