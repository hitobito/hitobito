#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Approver
  class Event < Base
    private

    # set state assigned for youth wagon
    def build_entity
      event.participations.where(person_id: request.person_id).first_or_initialize.tap do |p|
        build_role(p)
        set_active(p) if p.new_record?
      end
    end

    def role_type
      @role_type ||= event.find_role_type!(request.role_type)
    end

    def event
      request.body
    end

    private

    def set_active(participation)
      participation.active = true
    end

    def build_role(participation)
      if participation.roles.none? { |r| r.class.sti_name == request.role_type }
        role = participation.roles.build(type: role_type.sti_name)
        role.participation = participation
      end
    end
  end
end
