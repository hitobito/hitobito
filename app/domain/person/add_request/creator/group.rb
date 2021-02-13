# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Creator
  class Group < Base
    alias role entity

    def required?
      person.persisted? && super()
    end

    def body
      role.group
    end

    def person
      role.person
    end

    def request_attrs
      super.merge(role_type: entity.type)
    end
  end
end
