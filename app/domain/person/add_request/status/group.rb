#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Status
  class Group < Base
    def created?
      Role.where(group_id: body_id, person_id: person_id).exists?
    end
  end
end
