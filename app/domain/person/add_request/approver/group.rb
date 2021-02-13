# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Approver
  class Group < Base
    private

    def build_entity
      role_type.
        where(person_id: request.person_id, group_id: request.body_id).
        first_or_initialize
    end

    def role_type
      request.body.class.find_role_type!(request.role_type)
    end
  end
end
