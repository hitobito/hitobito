# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Status
  class Event < Base
    def created?
      ::Event::Participation.where(event_id: body_id, person_id: person_id).exists?
    end
  end
end
